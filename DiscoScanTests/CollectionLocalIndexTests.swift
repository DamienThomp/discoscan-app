//
//  CollectionLocalIndexTests.swift
//  DiscoScanTests
//

import SwiftData
import Testing
@testable import DiscoScan

struct CollectionLocalIndexTests {
    private let username = "tester"

    private func makeIndex() throws -> CollectionLocalIndex {
        CollectionLocalIndex(modelContainer: try TestModelContainer.make())
    }

    private func secondSampleItem(instanceId: Int) -> CollectionReleaseItem {
        CollectionReleaseItem(
            releaseId: 101,
            instanceId: instanceId,
            folderId: 2,
            dateAdded: "2024-02-01T12:00:00-00:00",
            basicInformation: ReleaseBasicInformation(
                id: 101,
                title: "Second Release",
                year: 2021,
                thumb: nil,
                coverImage: nil,
                resourceURL: nil,
                artists: [DiscogsArtist(id: 2, name: "Another Artist")],
                labels: [DiscogsLabel(id: 2, name: "Another Label", catno: "CAT-2")],
                formats: []
            )
        )
    }

    @Test func upsertLiveAndDeleteUpdateCount() async throws {
        let index = try makeIndex()
        let item = CollectionFixtures.sampleReleases[0]

        try await index.upsertLive(item, username: username)
        #expect(try await index.count(username: username) == 1)

        try await index.delete(instanceId: item.instanceId, username: username)
        #expect(try await index.count(username: username) == 0)
    }

    @Test func sweepRemovesOrphans() async throws {
        let index = try makeIndex()
        let kept = CollectionFixtures.sampleReleases[0]
        let orphan = secondSampleItem(instanceId: 2001)

        try await index.upsertLive(orphan, username: username)
        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([kept], username: username, generation: generation)

        let removed = try await index.sweep(username: username, keeping: generation)
        #expect(removed == 1)
        #expect(try await index.count(username: username) == 1)

        let items = try await index.allItems(username: username)
        #expect(items.map(\.instanceId) == [kept.instanceId])
    }

    @Test func upsertLiveDuringSyncSurvivesSweep() async throws {
        let index = try makeIndex()
        let synced = CollectionFixtures.sampleReleases[0]
        let liveAdded = secondSampleItem(instanceId: 3001)

        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([synced], username: username, generation: generation)
        try await index.upsertLive(liveAdded, username: username)

        _ = try await index.sweep(username: username, keeping: generation)

        let instanceIds = Set(try await index.allItems(username: username).map(\.instanceId))
        #expect(instanceIds.contains(synced.instanceId))
        #expect(instanceIds.contains(liveAdded.instanceId))
    }

    @Test func searchUsesTokenizedMatching() async throws {
        let index = try makeIndex()
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)

        let forward = try await index.search(username: username, query: "test release")
        let reversed = try await index.search(username: username, query: "release test")

        #expect(forward.count == 1)
        #expect(reversed.count == 1)
    }
}
