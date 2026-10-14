//
//  CollectionSyncService.swift
//  DiscoScan
//

import Foundation
import NetworkKit

enum CollectionSyncPhase: Equatable, Sendable {
    case idle
    case checking
    case syncing(synced: Int, total: Int)
    case failed(String)
}

enum CollectionSyncMode: Sendable {
    case ifNeeded
    case force
}

enum CollectionSyncError: LocalizedError, Equatable {
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

protocol CollectionSyncServiceProtocol: Sendable {
    func progressStream() async -> AsyncStream<CollectionSyncPhase>
    @discardableResult
    func refresh(username: String, mode: CollectionSyncMode) async -> CollectionSyncPhase
    func cancel(username: String) async
}

/// Syncs the Discogs folder id `.zero` ("All") into the local SwiftData collection index.
actor CollectionSyncService: CollectionSyncServiceProtocol {
    private let index: any CollectionLocalIndexProtocol
    private let apiClient: NetworkManagerProtocol
    private let staleAfter: TimeInterval
    private let now: @Sendable () -> Date
    private var inFlightRefreshByUsername: [String: Task<CollectionSyncPhase, Never>] = [:]
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

    func refresh(username: String, mode: CollectionSyncMode) async -> CollectionSyncPhase {
        if let inFlightRefresh = inFlightRefreshByUsername[username] {
            return await inFlightRefresh.value
        }

        let task = Task { await performRefresh(username: username, mode: mode) }
        inFlightRefreshByUsername[username] = task
        let phase = await task.value
        inFlightRefreshByUsername.removeValue(forKey: username)
        return phase
    }

    func cancel(username: String) async {
        guard let task = inFlightRefreshByUsername[username] else { return }
        task.cancel()
        _ = await task.value
    }

    private func performRefresh(username: String, mode: CollectionSyncMode) async -> CollectionSyncPhase {
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

            let needsSync = mode == .force
                || localTotal != remoteTotal
                || isUnsealed
                || isStale

            guard needsSync else {
                emit(.idle)
                return .idle
            }

            emit(.checking)

            let generation = try await index.beginSyncGeneration(username: username)
            let syncedTotal = try await paginateAndUpsert(
                username: username,
                generation: generation,
                remoteTotal: remoteTotal
            )

            guard syncedTotal == remoteTotal else {
                throw CollectionSyncError.incompleteSync(expected: remoteTotal, received: syncedTotal)
            }

            _ = try await index.sweep(username: username, keeping: generation)
            emit(.idle)
            return .idle
        } catch is CancellationError {
            emit(.idle)
            return .idle
        } catch {
            let phase = CollectionSyncPhase.failed(error.localizedDescription)
            emit(phase)
            return phase
        }
    }

    private func isIndexStale(lastSyncedAt: Date?) -> Bool {
        guard let lastSyncedAt else { return true }
        return now().timeIntervalSince(lastSyncedAt) > staleAfter
    }

    private func paginateAndUpsert(
        username: String,
        generation: Int,
        remoteTotal: Int
    ) async throws -> Int {
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
                emit(.syncing(synced: min(synced, remoteTotal), total: remoteTotal))

                guard page < response.pagination.pages else { break }
                page += 1
            } catch let error as CollectionSyncError {
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw CollectionSyncError.paginationFailed(page: page, message: error.localizedDescription)
            }
        }

        return synced
    }

    private func emit(_ phase: CollectionSyncPhase) {
        for continuation in progressContinuations.values {
            continuation.yield(phase)
        }
    }

    private func removeContinuation(id: UUID) {
        progressContinuations.removeValue(forKey: id)
    }
}
