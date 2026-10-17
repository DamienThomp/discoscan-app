//
//  CollectionSyncServiceTests.swift
//  DiscoScanTests
//

import Foundation
import SwiftData
import Testing
@testable import DiscoScan

@MainActor
struct CollectionSyncServiceTests {
    private let username = "tester"

    private func makeService(
        apiClient: MockCollectionNetworkClient,
        index: CollectionLocalIndex? = nil,
        staleAfter: TimeInterval = 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) throws -> (CollectionSyncService, CollectionLocalIndex) {
        let resolvedIndex: CollectionLocalIndex
        if let index {
            resolvedIndex = index
        } else {
            resolvedIndex = CollectionLocalIndex(modelContainer: try TestModelContainer.make())
        }
        let service = CollectionSyncService(
            index: resolvedIndex,
            apiClient: apiClient,
            staleAfter: staleAfter,
            now: now
        )
        return (service, resolvedIndex)
    }

    private func collectPhasesUntilTerminal(
        from stream: AsyncStream<CollectionSyncPhase>
    ) -> Task<[CollectionSyncPhase], Never> {
        Task {
            var phases: [CollectionSyncPhase] = []
            for await phase in stream {
                phases.append(phase)
                switch phase {
                case .idle, .failed:
                    return phases
                case .checking, .syncing:
                    continue
                }
            }
            return phases
        }
    }

    private func makeItem(instanceId: Int) -> CollectionReleaseItem {
        CollectionStoreTestSupport.sampleSnapshot.asCollectionReleaseItem(
            releaseId: instanceId,
            instanceId: instanceId,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00-00:00"
        )
    }

    @Test func `Count match skips pagination`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        let currentTime = Date()
        let (service, index) = try makeService(
            apiClient: apiClient,
            staleAfter: 60 * 60,
            now: { currentTime }
        )
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([CollectionFixtures.sampleReleases[0]], username: username, generation: generation)
        _ = try await index.sweep(username: username, keeping: generation)

        let progressTask = collectPhasesUntilTerminal(from: await service.progressStream())
        _ = await service.refresh(username: username, mode: .ifNeeded)
        let phases = await progressTask.value

        #expect(!phases.contains(.checking))
        #expect(phases.contains(.idle))
        #expect(!phases.contains(where: {
            if case .syncing = $0 { return true }
            return false
        }))
        #expect(apiClient.requestCount == 1)
    }

    @Test func `Count mismatch runs mark and sweep`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        let (service, index) = try makeService(apiClient: apiClient)

        _ = await service.refresh(username: username, mode: .ifNeeded)

        #expect(try await index.count(username: username) == 1)
        #expect(try await index.hasUnsealedGeneration(username: username) == false)
        #expect(apiClient.requestCount >= 2)
    }

    @Test func `Force sync runs when counts match`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        let (service, index) = try makeService(apiClient: apiClient)
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)

        _ = await service.refresh(username: username, mode: .force)

        #expect(apiClient.requestCount >= 2)
        #expect(try await index.hasUnsealedGeneration(username: username) == false)
    }

    @Test func `Stale last synced triggers sync`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        final class MutableDate: @unchecked Sendable {
            var value: Date
            init(_ value: Date) { self.value = value }
        }
        let clock = MutableDate(Date())
        let (service, index) = try makeService(
            apiClient: apiClient,
            staleAfter: 60,
            now: { clock.value }
        )
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([CollectionFixtures.sampleReleases[0]], username: username, generation: generation)
        _ = try await index.sweep(username: username, keeping: generation)

        clock.value = clock.value.addingTimeInterval(120)
        let requestsBeforeStaleRefresh = apiClient.requestCount
        _ = await service.refresh(username: username, mode: .ifNeeded)
        #expect(apiClient.requestCount - requestsBeforeStaleRefresh >= 2)
    }

    @Test func `Fresh last synced skips sync when counts match`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        let currentTime = Date()
        let (service, index) = try makeService(
            apiClient: apiClient,
            staleAfter: 60 * 60,
            now: { currentTime }
        )
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([CollectionFixtures.sampleReleases[0]], username: username, generation: generation)
        _ = try await index.sweep(username: username, keeping: generation)

        let requestsBeforeFreshCheck = apiClient.requestCount
        _ = await service.refresh(username: username, mode: .ifNeeded)
        #expect(apiClient.requestCount - requestsBeforeFreshCheck == 1)
    }

    @Test func `Remote removal is swept on sync`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 0
        apiClient.folderZeroPages = [[]]
        let (service, index) = try makeService(apiClient: apiClient)
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        #expect(try await index.count(username: username) == 1)

        _ = await service.refresh(username: username, mode: .ifNeeded)

        #expect(try await index.count(username: username) == 0)
    }

    @Test func `Unsealed generation retries even when counts match`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        let (service, index) = try makeService(apiClient: apiClient)
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        _ = try await index.beginSyncGeneration(username: username)

        _ = await service.refresh(username: username, mode: .ifNeeded)

        #expect(try await index.hasUnsealedGeneration(username: username) == false)
        #expect(apiClient.requestCount >= 2)
    }

    @Test func `Failure leaves generation unsealed for retry`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        apiClient.failOnFolderZeroPage = 1
        let (service, index) = try makeService(apiClient: apiClient)

        _ = await service.refresh(username: username, mode: .ifNeeded)
        #expect(try await index.hasUnsealedGeneration(username: username) == true)

        apiClient.failOnFolderZeroPage = nil
        _ = await service.refresh(username: username, mode: .ifNeeded)
        #expect(try await index.hasUnsealedGeneration(username: username) == false)
    }

    @Test func `Pagination failure keeps existing rows`() async throws {
        let existing = makeItem(instanceId: 3000)
        let firstPage = makeItem(instanceId: 3001)
        let secondPage = makeItem(instanceId: 3002)
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 2
        apiClient.folderZeroPages = [[firstPage], [secondPage]]
        apiClient.failOnFolderZeroPage = 2
        let (service, index) = try makeService(apiClient: apiClient)
        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([existing], username: username, generation: generation)
        _ = try await index.sweep(username: username, keeping: generation)

        let phase = await service.refresh(username: username, mode: .force)

        if case .failed = phase {
            #expect(Bool(true))
        } else {
            Issue.record("Expected failed phase after page 2 failure")
        }
        #expect(try await index.contains(instanceId: existing.instanceId, username: username))
        #expect(try await index.count(username: username) == 2)
        #expect(try await index.hasUnsealedGeneration(username: username))
    }

    @Test func `Cancelled network request is reported as idle, not failed`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        apiClient.delayNanoseconds = 500_000_000
        apiClient.reportsCancellationAsURLError = true
        let (service, _) = try makeService(apiClient: apiClient)

        let syncTask = Task {
            await service.refresh(username: username, mode: .force)
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        await service.cancel(username: username)

        #expect(await syncTask.value == .idle)
    }

    @Test func `Missing all folder emits failed`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.foldersMissingAllFolder = true
        let (service, _) = try makeService(apiClient: apiClient)

        let progressTask = collectPhasesUntilTerminal(from: await service.progressStream())
        _ = await service.refresh(username: username, mode: .ifNeeded)
        let phases = await progressTask.value

        #expect(phases.contains(where: {
            if case .failed = $0 { return true }
            return false
        }))
        #expect(!phases.contains(.idle))
    }

    @Test func `Incomplete pagination leaves generation unsealed`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 5
        apiClient.shortPaginationItems = 5
        apiClient.folderZeroPages = [Array(CollectionFixtures.sampleReleases.prefix(1))]
        let (service, index) = try makeService(apiClient: apiClient)

        let phase = await service.refresh(username: username, mode: .force)
        if case .failed = phase {
            #expect(Bool(true))
        } else {
            Issue.record("Expected failed phase for incomplete sync")
        }
        #expect(try await index.hasUnsealedGeneration(username: username) == true)
    }

    @Test func `Different usernames do not join the same sync`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 1
        apiClient.delayNanoseconds = 200_000_000
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases]
        let (service, _) = try makeService(apiClient: apiClient)

        async let first = service.refresh(username: "user-a", mode: .force)
        async let second = service.refresh(username: "user-b", mode: .force)
        _ = await (first, second)

        #expect(apiClient.requestCount >= 4)
    }

    @Test func `Cancel stops pagination and leaves generation unsealed`() async throws {
        let apiClient = MockCollectionNetworkClient()
        apiClient.folderZeroRemoteCount = 2
        apiClient.delayNanoseconds = 500_000_000
        apiClient.folderZeroPages = [CollectionFixtures.sampleReleases, CollectionFixtures.sampleReleases]
        let (service, index) = try makeService(apiClient: apiClient)

        let syncTask = Task {
            await service.refresh(username: username, mode: .force)
        }
        for _ in 0..<200 where apiClient.requestCount < 2 {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        await service.cancel(username: username)
        _ = await syncTask.value

        #expect(apiClient.requestCount == 2)
        let isUnsealed = try await index.hasUnsealedGeneration(username: username)
        #expect(isUnsealed)
    }
}
