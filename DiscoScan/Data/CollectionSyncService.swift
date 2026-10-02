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

enum CollectionSyncError: LocalizedError, Equatable {
    case allFolderNotFound
    case paginationFailed(page: Int, message: String)
    case indexWriteFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .allFolderNotFound:
            "Couldn't read your collection size from Discogs."
        case .paginationFailed(let page, let message):
            "Couldn't sync collection page \(page): \(message)"
        case .indexWriteFailed(let message):
            "Couldn't save collection index: \(message)"
        }
    }
}

protocol CollectionSyncServiceProtocol: Sendable {
    func progressStream() async -> AsyncStream<CollectionSyncPhase>
    @discardableResult
    func refreshIfNeeded(username: String, forceFoldersRefresh: Bool) async -> CollectionSyncPhase
    func repairIfUnsealed(username: String) async
}

/// Syncs the Discogs folder id `.zero` ("All") into the local SwiftData collection index.
actor CollectionSyncService: CollectionSyncServiceProtocol {
    private let index: any CollectionLocalIndexProtocol
    private let cachedFetcher: any CachedFetcherProtocol
    private var inFlightRefresh: Task<CollectionSyncPhase, Never>?
    private var progressContinuations: [UUID: AsyncStream<CollectionSyncPhase>.Continuation] = [:]

    init(
        index: any CollectionLocalIndexProtocol,
        cachedFetcher: any CachedFetcherProtocol
    ) {
        self.index = index
        self.cachedFetcher = cachedFetcher
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

    func refreshIfNeeded(username: String, forceFoldersRefresh: Bool) async -> CollectionSyncPhase {
        if let inFlightRefresh {
            return await inFlightRefresh.value
        }

        let task = Task { await performRefresh(username: username, forceFoldersRefresh: forceFoldersRefresh) }
        inFlightRefresh = task
        let phase = await task.value
        inFlightRefresh = nil
        return phase
    }

    func repairIfUnsealed(username: String) async {
        do {
            if try await index.hasUnsealedGeneration(username: username) {
                let _ = await refreshIfNeeded(username: username, forceFoldersRefresh: false)
            }
        } catch {
            emit(.failed(error.localizedDescription))
        }
    }

    private func performRefresh(username: String, forceFoldersRefresh: Bool) async -> CollectionSyncPhase {
        do {
            emit(.checking)

            let foldersResponse = try await cachedFetcher.fetch(
                CollectionFoldersEndpoint(userName: username),
                key: "collectionFolders",
                scope: .collection,
                forceRefresh: forceFoldersRefresh
            )

            guard let remoteTotal = foldersResponse.allFolder?.count else {
                throw CollectionSyncError.allFolderNotFound
            }

            let localTotal = try await index.count(username: username)
            let isUnsealed = try await index.hasUnsealedGeneration(username: username)
            guard localTotal != remoteTotal || isUnsealed else {
                emit(.idle)
                return .idle
            }

            let generation = try await index.beginSyncGeneration(username: username)
            try await paginateAndUpsert(
                username: username,
                generation: generation,
                remoteTotal: remoteTotal
            )
            _ = try await index.sweep(username: username, keeping: generation)
            emit(.idle)
            return .idle
        } catch {
            let phase = CollectionSyncPhase.failed(error.localizedDescription)
            emit(phase)
            return phase
        }
    }

    private func paginateAndUpsert(
        username: String,
        generation: Int,
        remoteTotal: Int
    ) async throws {
        var page = 1
        var synced = 0

        while true {
            do {
                let response = try await cachedFetcher.fetch(
                    CollectionItemsByFolderEndpoint(
                        username: username,
                        folderId: .zero,
                        page: page,
                        perPage: 100
                    ),
                    key: "collectionFolder-\(Int.zero)-page-\(page)",
                    scope: .collection,
                    forceRefresh: true
                )

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
            } catch {
                throw CollectionSyncError.paginationFailed(page: page, message: error.localizedDescription)
            }
        }
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
