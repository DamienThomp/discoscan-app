//
//  CollectionLocalIndexTests.swift
//  DiscoScanTests
//

import Foundation
import SwiftData
import Testing
@testable import DiscoScan

private enum TestSaveError: Error {
    case failed
}

@MainActor
struct CollectionLocalIndexTests {
    private let username = "tester"

    private func makeIndex() throws -> CollectionLocalIndex {
        CollectionLocalIndex(modelContainer: try TestModelContainer.make())
    }

    private func secondSampleItem(instanceId: Int, releaseId: Int = 101) -> CollectionReleaseItem {
        CollectionReleaseItem(
            releaseId: releaseId,
            instanceId: instanceId,
            folderId: 2,
            dateAdded: "2024-02-01T12:00:00-00:00",
            basicInformation: ReleaseBasicInformation(
                id: releaseId,
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

    @Test func `Upsert live and delete update count`() async throws {
        let index = try makeIndex()
        let item = CollectionFixtures.sampleReleases[0]

        try await index.upsertLive(item, username: username)
        #expect(try await index.count(username: username) == 1)

        try await index.delete(instanceId: item.instanceId, username: username)
        #expect(try await index.count(username: username) == 0)
    }

    @Test func `Sweep removes orphans`() async throws {
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

    @Test func `Upsert live during sync survives sweep`() async throws {
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

    @Test func `Batched upsert updates and inserts rows`() async throws {
        let index = try makeIndex()
        let existing = CollectionFixtures.sampleReleases[0]
        let inserted = secondSampleItem(instanceId: 5001)
        try await index.upsertLive(existing, username: username)

        let generation = try await index.beginSyncGeneration(username: username)
        let updated = CollectionReleaseItem(
            releaseId: existing.releaseId,
            instanceId: existing.instanceId,
            folderId: existing.folderId,
            dateAdded: existing.dateAdded,
            basicInformation: ReleaseBasicInformation(
                id: existing.basicInformation.id,
                title: "Updated Title",
                year: existing.basicInformation.year,
                thumb: existing.basicInformation.thumb,
                coverImage: existing.basicInformation.coverImage,
                resourceURL: existing.basicInformation.resourceURL,
                artists: existing.basicInformation.artists,
                labels: existing.basicInformation.labels,
                formats: existing.basicInformation.formats
            )
        )
        try await index.upsertSynced([updated, inserted], username: username, generation: generation)

        let titles = try await index.allItems(username: username).map(\.basicInformation.title)
        #expect(titles.contains("Updated Title"))
        #expect(titles.contains("Second Release"))
    }

    @Test func `Duplicate release instances are both stored`() async throws {
        let index = try makeIndex()
        let first = secondSampleItem(instanceId: 6001, releaseId: 999)
        let second = secondSampleItem(instanceId: 6002, releaseId: 999)

        try await index.upsertLive(first, username: username)
        try await index.upsertLive(second, username: username)

        #expect(try await index.count(username: username) == 2)
    }

    @Test func `Items sort by dateAddedAt with mixed offsets`() async throws {
        let index = try makeIndex()
        let utcItem = CollectionReleaseItem(
            releaseId: 1,
            instanceId: 7001,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00Z",
            basicInformation: CollectionFixtures.sampleReleases[0].basicInformation
        )
        let offsetItem = CollectionReleaseItem(
            releaseId: 2,
            instanceId: 7002,
            folderId: 1,
            dateAdded: "2024-06-01T12:00:00-07:00",
            basicInformation: CollectionFixtures.sampleReleases[0].basicInformation
        )

        try await index.upsertLive(utcItem, username: username)
        try await index.upsertLive(offsetItem, username: username)

        let instanceIds = try await index.allItems(username: username).map(\.instanceId)
        #expect(instanceIds.first == offsetItem.instanceId)
    }

    @Test func `Read-only metadata queries do not create rows`() async throws {
        let index = try makeIndex()

        #expect(try await index.hasUnsealedGeneration(username: username) == false)
        #expect(try await index.lastSyncedAt(username: username) == nil)
        #expect(try await index.count(username: username) == 0)
    }

    @Test func `Sweep sets last synced at`() async throws {
        let index = try makeIndex()
        try await index.upsertLive(CollectionFixtures.sampleReleases[0], username: username)
        let generation = try await index.beginSyncGeneration(username: username)
        try await index.upsertSynced([CollectionFixtures.sampleReleases[0]], username: username, generation: generation)
        _ = try await index.sweep(username: username, keeping: generation)

        let lastSynced = try await index.lastSyncedAt(username: username)
        #expect(lastSynced != nil)
    }

    @Test func `Searchable text and matching use shared implementation`() async throws {
        let item = CollectionFixtures.sampleReleases[0]
        let forward = CollectionSearchMatching.matches(query: "test release", searchableText: item.searchableText)
        let reversed = CollectionSearchMatching.matches(query: "release test", searchableText: item.searchableText)
        #expect(forward)
        #expect(reversed)
    }

    @Test func `Rollback reverts insert`() async throws {
        let index = try makeIndex()
        let first = CollectionFixtures.sampleReleases[0]
        let second = secondSampleItem(instanceId: 4001)

        await index.setSaveOverride { throw TestSaveError.failed }
        await #expect(throws: TestSaveError.self) {
            try await index.upsertLive(first, username: username)
        }
        #expect(try await index.count(username: username) == 0)

        await index.setSaveOverride(nil)
        try await index.upsertLive(second, username: username)
        #expect(try await index.count(username: username) == 1)
        #expect(try await index.allItems(username: username).map(\.instanceId) == [second.instanceId])
    }

    @Test func `Rollback reverts update`() async throws {
        let index = try makeIndex()
        let original = CollectionFixtures.sampleReleases[0]
        try await index.upsertLive(original, username: username)

        let updated = CollectionReleaseItem(
            releaseId: original.releaseId,
            instanceId: original.instanceId,
            folderId: original.folderId,
            dateAdded: original.dateAdded,
            basicInformation: ReleaseBasicInformation(
                id: original.basicInformation.id,
                title: "Updated Title",
                year: original.basicInformation.year,
                thumb: original.basicInformation.thumb,
                coverImage: original.basicInformation.coverImage,
                resourceURL: original.basicInformation.resourceURL,
                artists: original.basicInformation.artists,
                labels: original.basicInformation.labels,
                formats: original.basicInformation.formats
            )
        )

        await index.setSaveOverride { throw TestSaveError.failed }
        await #expect(throws: TestSaveError.self) {
            try await index.upsertLive(updated, username: username)
        }

        let items = try await index.allItems(username: username)
        #expect(items.first?.basicInformation.title == original.basicInformation.title)
    }

    @Test func `Rollback reverts delete`() async throws {
        let index = try makeIndex()
        let item = CollectionFixtures.sampleReleases[0]
        try await index.upsertLive(item, username: username)

        await index.setSaveOverride { throw TestSaveError.failed }
        await #expect(throws: TestSaveError.self) {
            try await index.delete(instanceId: item.instanceId, username: username)
        }
        #expect(try await index.count(username: username) == 1)

        await index.setSaveOverride(nil)
        try await index.delete(instanceId: item.instanceId, username: username)
        #expect(try await index.count(username: username) == 0)
    }
}
