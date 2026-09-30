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

protocol CollectionSyncServiceProtocol: Sendable {
    func progressStream() async -> AsyncStream<CollectionSyncPhase>
    func refreshIfNeeded(username: String, forceFoldersRefresh: Bool) async
    func repairIfUnsealed(username: String) async
}

actor CollectionSyncService: CollectionSyncServiceProtocol {
    private let index: any CollectionLocalIndexProtocol
    private let cachedFetcher: any CachedFetcherProtocol
    private var isSyncInFlight = false
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

    func refreshIfNeeded(username: String, forceFoldersRefresh: Bool) async {
        await performRefresh(username: username, forceFoldersRefresh: forceFoldersRefresh)
    }

    func repairIfUnsealed(username: String) async {
        do {
            if try await index.hasUnsealedGeneration(username: username) {
                await performRefresh(username: username, forceFoldersRefresh: false)
            }
        } catch {
            emit(.failed(error.localizedDescription))
        }
    }

    private func performRefresh(username: String, forceFoldersRefresh: Bool) async {
        guard !isSyncInFlight else { return }
        isSyncInFlight = true
        defer { isSyncInFlight = false }

        do {
            emit(.checking)

            let foldersResponse = try await cachedFetcher.fetch(
                CollectionFoldersEndpoint(userName: username),
                key: "collectionFolders",
                scope: .collection,
                forceRefresh: forceFoldersRefresh
            )

            guard let remoteTotal = foldersResponse.folders.first(where: { $0.id == 0 })?.count else {
                emit(.idle)
                return
            }

            let localTotal = try await index.count(username: username)
            let isUnsealed = try await index.hasUnsealedGeneration(username: username)
            guard localTotal != remoteTotal || isUnsealed else {
                emit(.idle)
                return
            }

            let generation = try await index.beginSyncGeneration(username: username)
            try await paginateAndUpsert(
                username: username,
                generation: generation,
                remoteTotal: remoteTotal
            )
            _ = try await index.sweep(username: username, keeping: generation)
            emit(.idle)
        } catch {
            emit(.failed(error.localizedDescription))
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
            let response = try await cachedFetcher.fetch(
                CollectionItemsByFolderEndpoint(
                    username: username,
                    folderId: 0,
                    page: page,
                    perPage: 100
                ),
                key: "collectionFolder-0-page-\(page)",
                scope: .collection,
                forceRefresh: true
            )

            try await index.upsertSynced(response.releases, username: username, generation: generation)
            synced += response.releases.count
            emit(.syncing(synced: min(synced, remoteTotal), total: remoteTotal))

            guard page < response.pagination.pages else { break }
            page += 1
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
