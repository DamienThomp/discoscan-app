//
//  CollectionSyncService.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated enum CollectionSyncPhase: Equatable, Sendable {
    case idle
    case checking
    case syncing(synced: Int, total: Int)
    case failed(String)
}

nonisolated enum CollectionSyncError: LocalizedError, Equatable {
    case allFolderNotFound
    case paginationFailed(page: Int, message: String)
    case indexWriteFailed(message: String)
    case incompleteSync(expected: Int, received: Int)

    var errorDescription: String? {
        switch self {
        case .allFolderNotFound:
            "Couldn't read your collection size from Discogs."
        case .paginationFailed(let page, let message):
            "Couldn't sync collection page \(page): \(message)"
        case .indexWriteFailed(let message):
            "Couldn't save collection index: \(message)"
        case .incompleteSync(let expected, let received):
            "Collection sync incomplete: expected \(expected) items, received \(received)."
        }
    }
}

nonisolated protocol CollectionSyncServiceProtocol: Sendable {
    func progressStream() async -> AsyncStream<CollectionSyncPhase>
    @discardableResult
    func refresh(username: String, intent: CollectionSyncIntent) async -> CollectionSyncPhase
    func cancel(username: String) async
}

/// Syncs the Discogs folder id `.zero` ("All") into the local SwiftData collection index.
actor CollectionSyncService: CollectionSyncServiceProtocol {
    private struct InFlightRefresh {
        let id: UUID
        let task: Task<CollectionSyncPhase, Never>
        let intent: CollectionSyncIntent
        var progressVisibility: SyncProgressVisibility
    }

    private let index: any CollectionLocalIndexProtocol
    private let apiClient: NetworkManagerProtocol
    private let staleAfter: TimeInterval
    private let now: @Sendable () -> Date
    private var inFlightRefreshByUsername: [String: InFlightRefresh] = [:]
    private var progressContinuations: [UUID: AsyncStream<CollectionSyncPhase>.Continuation] = [:]

    init(
        index: any CollectionLocalIndexProtocol,
        apiClient: NetworkManagerProtocol,
        staleAfter: TimeInterval = 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.index = index
        self.apiClient = apiClient
        self.staleAfter = staleAfter
        self.now = now
    }

    func progressStream() -> AsyncStream<CollectionSyncPhase> {
        let id = UUID()
        return AsyncStream { continuation in
            progressContinuations[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    func refresh(username: String, intent: CollectionSyncIntent) async -> CollectionSyncPhase {
        if let inFlight = inFlightRefreshByUsername[username] {
            let phase = await inFlight.task.value
            if intent == .userInitiated, inFlight.intent != .userInitiated {
                return await refresh(username: username, intent: intent)
            }
            return phase
        }

        let refreshID = UUID()
        // Unstructured task: coalesced callers share this work; not cancelled when a waiter’s outer task is cancelled.
        let task = Task { await self.runRefresh(username: username, intent: intent, refreshID: refreshID) }
        inFlightRefreshByUsername[username] = InFlightRefresh(
            id: refreshID,
            task: task,
            intent: intent,
            progressVisibility: .showProgress
        )
        return await task.value
    }

    func cancel(username: String) async {
        guard let inFlight = inFlightRefreshByUsername[username] else { return }
        inFlight.task.cancel()
        _ = await inFlight.task.value
    }

    private func runRefresh(
        username: String,
        intent: CollectionSyncIntent,
        refreshID: UUID
    ) async -> CollectionSyncPhase {
        let phase = await performRefresh(username: username, intent: intent, refreshID: refreshID)
        finishRefresh(username: username, id: refreshID)
        return phase
    }

    private func finishRefresh(username: String, id: UUID) {
        if inFlightRefreshByUsername[username]?.id == id {
            inFlightRefreshByUsername.removeValue(forKey: username)
        }
    }

    private func performRefresh(
        username: String,
        intent: CollectionSyncIntent,
        refreshID: UUID
    ) async -> CollectionSyncPhase {
        do {
            let foldersResponse = try await apiClient.request(
                for: CollectionFoldersEndpoint(userName: username)
            )

            guard let remoteTotal = foldersResponse.allFolder?.count else {
                throw CollectionSyncError.allFolderNotFound
            }

            let localTotal = try await index.count(username: username)
            let isUnsealed = try await index.hasUnsealedGeneration(username: username)
            let lastSynced = try await index.lastSyncedAt(username: username)
            let isStale = isIndexStale(lastSyncedAt: lastSynced)

            let health = CollectionSyncDecision.deriveIndexHealth(
                localTotal: localTotal,
                remoteTotal: remoteTotal,
                isUnsealed: isUnsealed,
                isStale: isStale
            )
            let action = CollectionSyncDecision.decideSyncAction(health: health, intent: intent)

            switch action {
            case .skip:
                emit(.idle, username: username)
                return .idle
            case .fullSync(let visibility):
                setProgressVisibility(visibility, username: username, refreshID: refreshID)
                if visibility == .showProgress {
                    emit(.checking, username: username)
                }

                let generation = try await index.beginSyncGeneration(username: username)
                let result = try await paginateAndUpsert(
                    username: username,
                    generation: generation,
                    remoteTotal: remoteTotal
                )

                guard result.synced == result.expected else {
                    throw CollectionSyncError.incompleteSync(expected: result.expected, received: result.synced)
                }

                _ = try await index.sweep(username: username, keeping: generation)
                emit(.idle, username: username)
                return .idle
            }
        } catch is CancellationError {
            emit(.idle, username: username)
            return .idle
        } catch {
            if Task.isCancelled {
                emit(.idle, username: username)
                return .idle
            }
            let phase = CollectionSyncPhase.failed(error.localizedDescription)
            emit(phase, username: username)
            return phase
        }
    }

    private func setProgressVisibility(
        _ visibility: SyncProgressVisibility,
        username: String,
        refreshID: UUID
    ) {
        guard var inFlight = inFlightRefreshByUsername[username], inFlight.id == refreshID else { return }
        inFlight.progressVisibility = visibility
        inFlightRefreshByUsername[username] = inFlight
    }

    private func isIndexStale(lastSyncedAt: Date?) -> Bool {
        guard let lastSyncedAt else { return true }
        return now().timeIntervalSince(lastSyncedAt) > staleAfter
    }

    private func paginateAndUpsert(
        username: String,
        generation: Int,
        remoteTotal: Int
    ) async throws -> (synced: Int, expected: Int) {
        var page = 1
        var synced = 0
        var expectedItems: Int?

        while true {
            try Task.checkCancellation()

            do {
                let response = try await apiClient.request(
                    for: CollectionItemsByFolderEndpoint(
                        username: username,
                        folderId: .zero,
                        page: page,
                        perPage: 100
                    )
                )

                if expectedItems == nil {
                    expectedItems = response.pagination.items
                }

                do {
                    try await index.upsertSynced(response.releases, username: username, generation: generation)
                } catch {
                    throw CollectionSyncError.indexWriteFailed(message: error.localizedDescription)
                }

                synced += response.releases.count
                emit(.syncing(synced: min(synced, remoteTotal), total: remoteTotal), username: username)

                guard page < response.pagination.pages else { break }
                page += 1
            } catch let error as CollectionSyncError {
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // URLSession reports task cancellation as URLError(.cancelled), not CancellationError.
                if Task.isCancelled {
                    throw CancellationError()
                }
                throw CollectionSyncError.paginationFailed(page: page, message: error.localizedDescription)
            }
        }

        return (synced, expectedItems ?? remoteTotal)
    }

    private func emit(_ phase: CollectionSyncPhase, username: String) {
        switch phase {
        case .checking, .syncing:
            guard inFlightRefreshByUsername[username]?.progressVisibility == .showProgress else { return }
        case .idle, .failed:
            break
        }

        for continuation in progressContinuations.values {
            continuation.yield(phase)
        }
    }

    private func removeContinuation(id: UUID) {
        progressContinuations.removeValue(forKey: id)
    }
}
