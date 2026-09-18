//
//  CollectionStoreTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
struct CollectionStoreTests {

    private let identity = DiscogsIdentity(
        id: 1,
        username: "tester",
        resourceURL: URL(string: "https://api.discogs.com/users/tester"),
        consumerName: "DiscoScan"
    )

    @Test func syncResetsOnLogout() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        #expect(store.folders == .loaded(CollectionFixtures.sampleFolders))

        store.sync(with: .unauthenticated)
        #expect(store.folders == .idle)
        #expect(store.releasesByFolderID.isEmpty)
    }

    @Test func syncResetsWhenUsernameChanges() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        let otherIdentity = DiscogsIdentity(
            id: 2,
            username: "other",
            resourceURL: nil,
            consumerName: nil
        )
        store.sync(with: .authenticated(otherIdentity))
        #expect(store.folders == .idle)
    }

    @Test func loadFoldersTransitionsToLoaded() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        #expect(store.folders == .loaded(CollectionFixtures.sampleFolders))
        #expect(fetcher.lastFetch?.forceRefresh == false)
        #expect(fetcher.lastFetch?.key == "collectionFolders")
        #expect(fetcher.lastFetch?.userScope == "tester")
    }

    @Test func loadFoldersFailsWhenNotAuthenticated() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        await store.loadFolders()

        if case .failed = store.folders {
            #expect(Bool(true))
        } else {
            Issue.record("Expected folders to fail when unauthenticated")
        }
    }

    @Test func loadReleasesStoresPaginationAndItems() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)

        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
        #expect(store.canLoadMore(folderId: 1))
        #expect(fetcher.lastFetch?.key == "collectionFolder-1-page-1")
    }

    @Test func createFolderRefreshesWithForceRefresh() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        let folderName = try #require(try FolderName.validated(from: "New Folder").get())
        try await store.createFolder(name: folderName)

        #expect(apiClient.lastRequestPath?.contains("/collection/folders") == true)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func deleteFolderRejectsSystemFolders() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteFolder(id: 1)

        #expect(apiClient.requestCount == 0)
        #expect(store.lastMutationError == CollectionStoreError.systemFolderNotDeletable.localizedDescription)
    }

    @Test func deleteFolderCallsEndpointAndRefreshes() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 2)
        await store.deleteFolder(id: 2)

        #expect(apiClient.lastRequestPath?.contains("/collection/folders/2") == true)
        #expect(store.releasesByFolderID[2] == nil)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func addReleaseRefreshesFolderAndFolders() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(releaseId: 249504)

        #expect(apiClient.lastRequestPath?.contains("/releases/249504") == true)
        #expect(fetcher.fetchCount >= 2)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func loadReleasesRefreshPreservesStaleDataWhileFetching() async {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.delayNanoseconds = 100_000_000
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))

        async let refresh: Void = store.loadReleases(folderId: 1, forceRefresh: true)
        try? await Task.sleep(for: .milliseconds(10))
        #expect(store.releasesByFolderID[1] == .refreshing(CollectionFixtures.sampleReleases))
        await refresh
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func loadReleasesRefreshFailurePreservesStaleData() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        fetcher.shouldFail = true
        await store.loadReleases(folderId: 1, forceRefresh: true)

        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func deleteReleaseRefreshesAffectedData() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteRelease(from: 1, releaseId: 100, instanceId: 1000)

        #expect(apiClient.lastRequestPath?.contains("/instances/1000") == true)
        #expect(fetcher.fetchCount >= 2)
        #expect(store.lastMutationError == nil)
    }

    @Test func deleteReleaseExcludesItemFromRefreshStaleData() async {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.delayNanoseconds = 100_000_000
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)

        async let deletion: Void = store.deleteRelease(from: 1, releaseId: 100, instanceId: 1000)
        try? await Task.sleep(for: .milliseconds(10))
        #expect(store.releasesByFolderID[1] == .refreshing([]))
        await deletion
    }
}
