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

    @Test func syncResetsOnLogout() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        #expect(store.folders == .loaded(CollectionFixtures.sampleFolders))

        store.sync(with: .unauthenticated)
        #expect(store.folders == .idle)
        #expect(store.releasesByFolderID.isEmpty)
        #expect(store.folderZeroItems == .idle)
    }

    @Test func syncResetsWhenUsernameChanges() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

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

    @Test func loadFoldersTransitionsToLoaded() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        #expect(store.folders == .loaded(CollectionFixtures.sampleFolders))
        #expect(fetcher.lastFetch?.forceRefresh == false)
        #expect(fetcher.lastFetch?.key == "collectionFolders")
    }

    @Test func loadFoldersFailsWhenNotAuthenticated() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        await store.loadFolders()

        if case .failed = store.folders {
            #expect(Bool(true))
        } else {
            Issue.record("Expected folders to fail when unauthenticated")
        }
    }

    @Test func loadReleasesStoresPaginationAndItems() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)

        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
        #expect(store.canLoadMore(folderId: 1))
        #expect(fetcher.lastFetch?.key == "collectionFolder-1-page-1")
    }

    @Test func createFolderRefreshesWithForceRefresh() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        let folderName = try #require(try FolderName.validated(from: "New Folder").get())
        try await store.createFolder(name: folderName)

        #expect(apiClient.lastRequestPath?.contains("/collection/folders") == true)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func deleteFolderRejectsSystemFolders() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteFolder(id: 1)

        #expect(apiClient.requestCount == 0)
        #expect(store.lastMutationError == CollectionStoreError.systemFolderNotDeletable.localizedDescription)
    }

    @Test func deleteFolderCallsEndpointAndRefreshes() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 2)
        await store.deleteFolder(id: 2)

        #expect(apiClient.lastRequestPath?.contains("/collection/folders/2") == true)
        #expect(store.releasesByFolderID[2] == nil)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func `Add release upserts folder zero index without folder refresh`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(
            releaseId: 249504,
            folderId: 2,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )

        #expect(apiClient.lastRequestPath?.contains("/releases/249504") == true)
        #expect(store.folderZeroItems.value?.count == 1)
        #expect(store.folderZeroItems.value?.first?.folderId == 2)
        #expect(store.folderZeroItems.value?.first?.instanceId == 2000)
        #expect(fetcher.lastFetch?.key == "collectionFolders")
        #expect(store.lastMutationError == nil)
    }

    @Test func loadReleasesRefreshPreservesStaleDataWhileFetching() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.delayNanoseconds = 100_000_000
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))

        async let refresh: Void = store.loadReleases(folderId: 1, forceRefresh: true)
        try? await Task.sleep(for: .milliseconds(10))
        #expect(store.releasesByFolderID[1] == .refreshing(CollectionFixtures.sampleReleases))
        await refresh
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func refreshReleasesInvalidatesCachedPagesBeforeFetchingPageOne() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.refreshReleases(folderId: 1)

        #expect(fetcher.lastInvalidatedPrefix == "collectionFolder-1-page-")
        #expect(fetcher.lastFetch?.key == "collectionFolder-1-page-1")
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func loadReleasesRefreshFailurePreservesStaleData() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        fetcher.shouldFail = true
        await store.loadReleases(folderId: 1, forceRefresh: true)

        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func deleteReleaseRemovesItemLocallyAndRefreshesFoldersOnly() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        await store.addRelease(
            releaseId: 249504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )
        #expect(store.folderZeroItems.value?.count == 1)

        await store.deleteRelease(from: 1, releaseId: 249504, instanceId: 2000)

        #expect(apiClient.lastRequestPath?.contains("/instances/2000") == true)
        #expect(store.releasesByFolderID[1]?.value?.contains(where: { $0.instanceId == 2000 }) == false)
        #expect(store.releasesByFolderID[1]?.value?.count == CollectionFixtures.sampleReleases.count)
        #expect(store.folderZeroItems.value?.isEmpty == true)
        #expect(store.lastMutationError == nil)
    }

    @Test func refreshCollectionIndexSkipsSyncWhenCountsMatch() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folderZeroRemoteCount = 1
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(
            releaseId: 249504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )
        let fetchCountBeforeRefresh = fetcher.fetchCount

        await store.refreshCollectionIndex()

        #expect(store.folderZeroSync == .idle)
        #expect(fetcher.fetchCount == fetchCountBeforeRefresh + 1)
    }

    @Test func `Search folder zero matches tokens in either order`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(
            releaseId: 249504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )

        #expect(store.searchFolderZero(query: "test artist").count == 1)
        #expect(store.searchFolderZero(query: "artist test").count == 1)
        #expect(store.searchFolderZero(query: "missing").isEmpty)
    }

    @Test func `Ensure folder zero index ready loads from empty local index`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folderZeroRemoteCount = 1
        fetcher.folderZeroPages = [CollectionFixtures.sampleReleases]
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        await store.ensureFolderZeroIndexReady()

        #expect(store.folderZeroItems.value?.count == 1)
        #expect(store.folderZeroSync == .idle)
        #expect(fetcher.fetchCount >= 2)
    }

    @Test func `Sync folder zero index fails when all folder is missing`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.foldersMissingAllFolder = true
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        await store.syncFolderZeroIndex(forceRefresh: true)

        if case .failed = store.folderZeroItems {
            #expect(Bool(true))
        } else {
            Issue.record("Expected folderZeroItems to fail when all folder is missing")
        }
        if case .failed = store.folderZeroSync {
            #expect(Bool(true))
        } else {
            Issue.record("Expected folderZeroSync to fail when all folder is missing")
        }
    }

    @Test func `Sync folder zero index failure keeps failed state when local index is empty`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folderZeroRemoteCount = 2
        fetcher.failOnFolderZeroPage = 1
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        await store.syncFolderZeroIndex(forceRefresh: true)

        if case .failed = store.folderZeroItems {
            #expect(Bool(true))
        } else {
            Issue.record("Expected folderZeroItems to fail after sync error with empty local index")
        }
    }

    @Test func `Retry after sync failure succeeds`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        fetcher.folderZeroRemoteCount = 1
        fetcher.folderZeroPages = [CollectionFixtures.sampleReleases]
        fetcher.failOnFolderZeroPage = 1
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        await store.syncFolderZeroIndex(forceRefresh: true)
        if case .failed = store.folderZeroItems {
            #expect(Bool(true))
        } else {
            Issue.record("Expected first sync attempt to fail")
        }

        fetcher.failOnFolderZeroPage = nil
        await store.syncFolderZeroIndex(forceRefresh: true)

        #expect(store.folderZeroItems.value?.count == 1)
        #expect(store.folderZeroSync == .idle)
    }
}
