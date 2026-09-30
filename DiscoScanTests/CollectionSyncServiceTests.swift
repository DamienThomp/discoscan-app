//
//  CollectionSyncServiceTests.swift
//  DiscoScanTests
//

import SwiftData
import Testing
@testable import DiscoScan

struct CollectionSyncServiceTests {
    private let username = "tester"

    @Test func countMatchSkipsPagination() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folder0RemoteCount = 1
        let index = CollectionLocalIndex(modelContainer: try TestModelContainer.make())
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)

        let service = CollectionSyncService(index: index, cachedFetcher: fetcher)
        let stream = await service.progressStream()
        var phases: [CollectionSyncPhase] = []
        let progressTask = Task {
            for await phase in stream {
                phases.append(phase)
            }
        }

        await service.refreshIfNeeded(username: username, forceFoldersRefresh: true)
        progressTask.cancel()

        #expect(phases.contains(.checking))
        #expect(phases.contains(.idle))
        #expect(!phases.contains(where: {
            if case .syncing = $0 { return true }
            return false
        }))
        #expect(fetcher.fetchCount == 1)
    }

    @Test func countMismatchRunsMarkAndSweep() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folder0RemoteCount = 1
        fetcher.folder0Pages = [CollectionFixtures.sampleReleases]

        let index = CollectionLocalIndex(modelContainer: try TestModelContainer.make())
        let service = CollectionSyncService(index: index, cachedFetcher: fetcher)

        await service.refreshIfNeeded(username: username, forceFoldersRefresh: true)

        #expect(try await index.count(username: username) == 1)
        #expect(try await index.hasUnsealedGeneration(username: username) == false)
        #expect(fetcher.fetchCount >= 2)
    }

    @Test func remoteRemovalIsSweptOnRepair() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folder0RemoteCount = 0
        fetcher.folder0Pages = [[]]

        let index = CollectionLocalIndex(modelContainer: try TestModelContainer.make())
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        #expect(try await index.count(username: username) == 1)

        let service = CollectionSyncService(index: index, cachedFetcher: fetcher)
        await service.refreshIfNeeded(username: username, forceFoldersRefresh: true)

        #expect(try await index.count(username: username) == 0)
    }

    @Test func unsealedGenerationRetriesEvenWhenCountsMatch() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folder0RemoteCount = 1
        fetcher.folder0Pages = [CollectionFixtures.sampleReleases]

        let index = CollectionLocalIndex(modelContainer: try TestModelContainer.make())
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        _ = try await index.beginSyncGeneration(username: username)

        let service = CollectionSyncService(index: index, cachedFetcher: fetcher)
        await service.refreshIfNeeded(username: username, forceFoldersRefresh: true)

        #expect(try await index.hasUnsealedGeneration(username: username) == false)
        #expect(fetcher.fetchCount >= 2)
    }

    @Test func failureLeavesGenerationUnsealedForRetry() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folder0RemoteCount = 2
        fetcher.folder0Pages = [CollectionFixtures.sampleReleases]
        fetcher.failOnFolder0Page = 1

        let index = CollectionLocalIndex(modelContainer: try TestModelContainer.make())
        let service = CollectionSyncService(index: index, cachedFetcher: fetcher)

        await service.refreshIfNeeded(username: username, forceFoldersRefresh: true)
        #expect(try await index.hasUnsealedGeneration(username: username))

        fetcher.failOnFolder0Page = nil
        await service.refreshIfNeeded(username: username, forceFoldersRefresh: true)
        #expect(try await index.hasUnsealedGeneration(username: username) == false)
    }
}
