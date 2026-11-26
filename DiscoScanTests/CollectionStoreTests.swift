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

    @Test func `Sync resets on logout`() async throws {
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

    @Test func `Sync resets when username changes`() async throws {
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

    @Test func `Load folders transitions to loaded`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        #expect(store.folders == .loaded(CollectionFixtures.sampleFolders))
        #expect(await fetcher.lastFetch?.forceRefresh == false)
        #expect(await fetcher.lastFetch?.key == "collectionFolders")
    }

    @Test func `Load folders ignores stale result after logout`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        await fetcher.setDelayNanoseconds(200_000_000)
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        async let loadTask: Void = store.loadFolders()
        try await Task.sleep(for: .milliseconds(50))
        store.sync(with: .unauthenticated)
        await loadTask

        #expect(store.folders == .idle)
    }

    @Test func `Load folders fails when not authenticated`() async throws {
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

    @Test func `Load releases stores pagination and items`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)

        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
        #expect(store.canLoadMore(folderId: 1))
        #expect(await fetcher.lastFetch?.key == "collectionFolder-1-page-1")
    }

    @Test func `Create folder refreshes with forceRefresh`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        let folderName = try FolderName.validated(from: "New Folder").get()
        try await store.createFolder(name: folderName)

        #expect(await apiClient.lastRequestPath?.contains("/collection/folders") == true)
        #expect(await fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func `Delete folder rejects system folders`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteFolder(id: 1)

        #expect(await apiClient.requestCount == 0)
        #expect(store.lastMutationError == CollectionStoreError.systemFolderNotDeletable.localizedDescription)
    }

    @Test func `Delete folder rejects non-empty folder`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        await store.deleteFolder(id: 3)

        #expect(await apiClient.requestCount == 0)
        #expect(store.lastMutationError == CollectionStoreError.folderNotEmpty.localizedDescription)
    }

    @Test func `Delete folder calls endpoint and refreshes`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        await store.loadReleases(folderId: 2)
        await store.deleteFolder(id: 2)

        #expect(await apiClient.lastRequestPath?.contains("/collection/folders/2") == true)
        #expect(store.releasesByFolderID[2] == nil)
        #expect(await fetcher.lastFetch?.forceRefresh == true)
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

        #expect(await apiClient.lastRequestPath?.contains("/releases/249504") == true)
        #expect(store.folderZeroItems.value?.count == 1)
        #expect(store.folderZeroItems.value?.first?.folderId == 2)
        #expect(store.folderZeroItems.value?.first?.instanceId == 2000)
        #expect(await fetcher.lastFetch?.key == "collectionFolders")
        #expect(store.lastMutationError == nil)
    }

    @Test func `Load releases refresh preserves stale data while fetching`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        await fetcher.setDelayNanoseconds(100_000_000)
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

    @Test func `Refresh releases invalidates cached pages before fetching page one`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.refreshReleases(folderId: 1)

        #expect(await fetcher.lastInvalidatedPrefix == "collectionFolder-1-page-")
        #expect(await fetcher.lastFetch?.key == "collectionFolder-1-page-1")
        #expect(await fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func `Load releases refresh failure preserves stale data`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        await fetcher.setShouldFail(true)
        await store.loadReleases(folderId: 1, forceRefresh: true)

        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func `Load releases routes folder zero to index readiness`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(0)
        await apiClient.setFolderZeroPages([[]])
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        await store.loadReleases(folderId: .zero)

        #expect(store.folderZeroItems == .loaded([]))
        #expect(store.releasesByFolderID[.zero] == nil)
        #expect(await fetcher.lastFetch?.key != "collectionFolder-0-page-1")
    }

    @Test func `Load releases skips fetch when folder already loaded`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        let fetchCountAfterFirstLoad = await fetcher.fetchCount

        await store.loadReleases(folderId: 1)

        #expect(await fetcher.fetchCount == fetchCountAfterFirstLoad)
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func `Load releases on a loading folder doesn't fetch`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        await fetcher.setDelayNanoseconds(100_000_000)
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        async let firstLoad: Void = store.loadReleases(folderId: 1)
        try await Task.sleep(for: .milliseconds(10))
        await store.loadReleases(folderId: 1)
        await firstLoad

        #expect(await fetcher.fetchCount == 1)
    }

    @Test func `Load releases on a failed folder doesn't fetch, refreshReleases does`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        await fetcher.setShouldFail(true)
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        if case .failed = store.releasesByFolderID[1] {
            #expect(Bool(true))
        } else {
            Issue.record("Expected releases to fail")
        }

        let fetchCountAfterFailure = await fetcher.fetchCount
        await store.loadReleases(folderId: 1)
        #expect(await fetcher.fetchCount == fetchCountAfterFailure)

        await fetcher.setShouldFail(false)
        await store.refreshReleases(folderId: 1)
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func `Load releases with forceRefresh on a loaded folder still fetches`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)
        let fetchCountAfterFirstLoad = await fetcher.fetchCount

        await store.loadReleases(folderId: 1, forceRefresh: true)

        #expect(await fetcher.fetchCount > fetchCountAfterFirstLoad)
        #expect(store.releasesByFolderID[1] == .loaded(CollectionFixtures.sampleReleases))
    }

    @Test func `Refresh releases on folder zero doesn't invalidate folder endpoint cache`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(0)
        await apiClient.setFolderZeroPages([[]])
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        await store.refreshReleases(folderId: .zero)

        #expect(await fetcher.lastInvalidatedPrefix != "collectionFolder-0-page-")
    }

    @Test func `Delete release removes item locally and refreshes folders only`() async throws {
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

        #expect(await apiClient.lastRequestPath?.contains("/instances/2000") == true)
        #expect(store.releasesByFolderID[1]?.value?.contains(where: { $0.instanceId == 2000 }) == false)
        #expect(store.releasesByFolderID[1]?.value?.count == CollectionFixtures.sampleReleases.count)
        #expect(store.folderZeroItems.value?.isEmpty == true)
        #expect(store.lastMutationError == nil)
    }

    @Test func `Pull to refresh syncs when counts match`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        await apiClient.setFolderZeroPages([CollectionFixtures.sampleReleases])
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(
            releaseId: 249504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )
        let apiRequestsBeforeRefresh = await apiClient.requestCount

        await store.refreshCollectionIndex()

        #expect(store.folderZeroSync == .idle)
        #expect(await apiClient.requestCount > apiRequestsBeforeRefresh)
    }

    @Test func `Set folder zero sort order reorders items`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(2)
        let container = try TestModelContainer.make()
        let index = CollectionLocalIndex(modelContainer: container)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            modelContainer: container,
            localIndex: index
        )

        let older = CollectionReleaseItem(
            releaseId: 1,
            instanceId: 8001,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00Z",
            basicInformation: CollectionFixtures.sampleReleases[0].basicInformation
        )
        let newer = CollectionReleaseItem(
            releaseId: 2,
            instanceId: 8002,
            folderId: 1,
            dateAdded: "2024-06-01T12:00:00-07:00",
            basicInformation: CollectionFixtures.sampleReleases[0].basicInformation
        )

        store.sync(with: .authenticated(identity))
        try await index.upsertLive(older, username: identity.username)
        try await index.upsertLive(newer, username: identity.username)
        await store.loadReleases(folderId: .zero)

        #expect(store.folderZeroSort == .newestFirst)
        #expect(store.folderZeroItems.value?.first?.instanceId == newer.instanceId)

        await store.setFolderZeroSort(.oldestFirst)

        #expect(store.folderZeroSort == .oldestFirst)
        #expect(store.folderZeroItems.value?.first?.instanceId == older.instanceId)
    }

    @Test func `Set folder zero sort by artist reloads from index`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let container = try TestModelContainer.make()
        let index = CollectionLocalIndex(modelContainer: container)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            modelContainer: container,
            localIndex: index
        )

        let zzTop = CollectionReleaseItem(
            releaseId: 1,
            instanceId: 8101,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00Z",
            basicInformation: ReleaseBasicInformation(
                id: 1,
                title: "Eliminator",
                year: nil,
                thumb: nil,
                coverImage: nil,
                resourceURL: nil,
                artists: [DiscogsArtist(id: 1, name: "ZZ Top")],
                labels: [],
                formats: []
            )
        )
        let abba = CollectionReleaseItem(
            releaseId: 2,
            instanceId: 8102,
            folderId: 1,
            dateAdded: "2024-02-01T12:00:00Z",
            basicInformation: ReleaseBasicInformation(
                id: 2,
                title: "Arrival",
                year: nil,
                thumb: nil,
                coverImage: nil,
                resourceURL: nil,
                artists: [DiscogsArtist(id: 2, name: "abba")],
                labels: [],
                formats: []
            )
        )

        store.sync(with: .authenticated(identity))
        try await index.upsertLive(zzTop, username: identity.username)
        try await index.upsertLive(abba, username: identity.username)
        await store.loadReleases(folderId: .zero)

        await store.setFolderZeroSort(.artistAZ)

        #expect(store.folderZeroSort == .artistAZ)
        #expect(store.folderZeroItems.value?.map(\.instanceId) == [abba.instanceId, zzTop.instanceId])
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
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        await apiClient.setFolderZeroPages([CollectionFixtures.sampleReleases])
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        await store.ensureFolderZeroIndexReady()

        #expect(store.folderZeroItems.value?.count == 1)
        #expect(store.folderZeroSync == .idle)
        #expect(await fetcher.fetchCount >= 2)
    }

    @Test func `Sync folder zero index fails when all folder is missing`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFoldersMissingAllFolder(true)
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
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(2)
        await apiClient.setFailOnFolderZeroPage(1)
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
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        await apiClient.setFolderZeroPages([CollectionFixtures.sampleReleases])
        await apiClient.setFailOnFolderZeroPage(1)
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        await store.syncFolderZeroIndex(forceRefresh: true)
        if case .failed = store.folderZeroItems {
            #expect(Bool(true))
        } else {
            Issue.record("Expected first sync attempt to fail")
        }

        await apiClient.setFailOnFolderZeroPage(nil)
        await store.syncFolderZeroIndex(forceRefresh: true)

        #expect(store.folderZeroItems.value?.count == 1)
        #expect(store.folderZeroSync == .idle)
    }

    @Test func `Local write retry succeeds without full repair`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let failingIndex = FailingCollectionLocalIndex(delegate: realIndex, mode: .failOnceThenSucceed)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: failingIndex
        )

        store.sync(with: .authenticated(identity))
        await store.addRelease(
            releaseId: 249_504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )

        #expect(store.lastMutationError == nil)
        #expect(store.folderZeroItems.value?.count == 1)
        #expect(await fetcher.fetchCount == 1)
    }

    @Test func `Add release triggers repair when local upsert always fails`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let failingIndex = FailingCollectionLocalIndex(delegate: realIndex, mode: .alwaysFail)
        let fetcher = MockCollectionCachedFetcher()
        let repairedItem = CollectionStoreTestSupport.sampleSnapshot.asCollectionReleaseItem(
            releaseId: 249_504,
            instanceId: 2000,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00-00:00"
        )
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        await apiClient.setFolderZeroPages([[repairedItem]])
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: failingIndex
        )

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        await store.addRelease(
            releaseId: 249_504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )

        #expect(store.lastMutationError == nil)
        #expect(try await realIndex.contains(instanceId: 2000, username: identity.username))
    }

    @Test func `Add release surfaces error when local upsert and repair both fail`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let failingIndex = FailingCollectionLocalIndex(delegate: realIndex, mode: .alwaysFail)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFoldersMissingAllFolder(true)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: failingIndex
        )

        store.sync(with: .authenticated(identity))
        await store.addRelease(
            releaseId: 249_504,
            folderId: 1,
            snapshot: CollectionStoreTestSupport.sampleSnapshot
        )

        #expect(store.lastMutationError == CollectionStoreError.remoteAddSucceededLocalFailed.localizedDescription)
    }

    @Test func `Delete release triggers repair when local delete always fails`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let failingIndex = FailingCollectionLocalIndex(delegate: realIndex, mode: .alwaysFail)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(0)
        await apiClient.setFolderZeroPages([[]])
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: failingIndex
        )

        store.sync(with: .authenticated(identity))
        let instanceId = 2000
        let item = CollectionStoreTestSupport.sampleSnapshot.asCollectionReleaseItem(
            releaseId: 249_504,
            instanceId: instanceId,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00-00:00"
        )
        try await realIndex.upsertLive(item, username: identity.username)
        await store.loadFolders()

        await store.deleteRelease(from: 1, releaseId: 249_504, instanceId: instanceId)

        #expect(store.lastMutationError == nil)
        #expect(try await realIndex.contains(instanceId: instanceId, username: identity.username) == false)
    }

    @Test func `Repair completes when originating task is cancelled`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let failingIndex = FailingCollectionLocalIndex(delegate: realIndex, mode: .alwaysFail)
        let fetcher = MockCollectionCachedFetcher()
        let repairedItem = CollectionStoreTestSupport.sampleSnapshot.asCollectionReleaseItem(
            releaseId: 249_504,
            instanceId: 2000,
            folderId: 1,
            dateAdded: "2024-01-01T12:00:00-00:00"
        )
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        await apiClient.setFolderZeroPages([[repairedItem]])
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: failingIndex
        )

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        let addTask = Task {
            await store.addRelease(
                releaseId: 249_504,
                folderId: 1,
                snapshot: CollectionStoreTestSupport.sampleSnapshot
            )
        }
        addTask.cancel()
        _ = await addTask.value

        try await Task.sleep(for: .milliseconds(200))
        #expect(try await realIndex.contains(instanceId: 2000, username: identity.username))
    }

    @Test func `Folder zero sync shows progress after sign in`() async throws {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(2)
        await apiClient.setFolderZeroPages([3001, 3002].map { instanceId in
            [CollectionStoreTestSupport.sampleSnapshot.asCollectionReleaseItem(
                releaseId: instanceId,
                instanceId: instanceId,
                folderId: 1,
                dateAdded: "2024-01-01T12:00:00-00:00"
            )]
        })
        await apiClient.setDelayNanoseconds(200_000_000)
        let store = try CollectionStoreTestSupport.makeStore(fetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        let ensureTask = Task { await store.ensureFolderZeroIndexReady() }

        var sawSyncing = false
        for _ in 0..<100 {
            if case .syncing = store.folderZeroSync {
                sawSyncing = true
                break
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        _ = await ensureTask.value

        #expect(sawSyncing)
    }

    @Test func `User switch clears previous user index`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: realIndex
        )

        let firstUser = DiscogsIdentity(
            id: 1,
            username: "first-user",
            resourceURL: nil,
            consumerName: nil
        )
        let secondUser = DiscogsIdentity(
            id: 2,
            username: "second-user",
            resourceURL: nil,
            consumerName: nil
        )
        try await realIndex.upsertLive(CollectionFixtures.sampleReleases[0], username: firstUser.username)

        store.sync(with: .authenticated(firstUser))
        store.sync(with: .authenticated(secondUser))
        try await Task.sleep(for: .milliseconds(200))

        #expect(try await realIndex.count(username: firstUser.username) == 0)
    }

    @Test func `User switch cancels running sync before clearing`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let pages = [3001, 3002].map { instanceId in
            [CollectionStoreTestSupport.sampleSnapshot.asCollectionReleaseItem(
                releaseId: instanceId,
                instanceId: instanceId,
                folderId: 1,
                dateAdded: "2024-01-01T12:00:00-00:00"
            )]
        }
        await apiClient.setFolderZeroRemoteCount(2)
        await apiClient.setFolderZeroPages(pages)
        await apiClient.setDelayNanoseconds(100_000_000)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: realIndex
        )
        let firstUser = DiscogsIdentity(id: 1, username: "first-user", resourceURL: nil, consumerName: nil)
        let secondUser = DiscogsIdentity(id: 2, username: "second-user", resourceURL: nil, consumerName: nil)

        store.sync(with: .authenticated(firstUser))
        let ensureTask = Task { await store.ensureFolderZeroIndexReady() }
        for _ in 0..<100 {
            if await apiClient.requestCount != 0 { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        store.sync(with: .authenticated(secondUser))
        await ensureTask.value
        try await Task.sleep(for: .milliseconds(300))

        #expect(try await realIndex.count(username: firstUser.username) == 0)
        #expect(try await realIndex.hasUnsealedGeneration(username: firstUser.username) == false)
    }

    @Test func `Ensure returns before background sync when locally loaded`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        await apiClient.setFolderZeroPages([CollectionFixtures.sampleReleases])
        await apiClient.setDelayNanoseconds(500_000_000)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: realIndex
        )

        try await realIndex.upsertLive(CollectionFixtures.sampleReleases[0], username: identity.username)
        let generation = try await realIndex.beginSyncGeneration(username: identity.username)
        try await realIndex.upsertSynced(
            [CollectionFixtures.sampleReleases[0]],
            username: identity.username,
            generation: generation
        )
        _ = try await realIndex.sweep(username: identity.username, keeping: generation)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: .zero)

        let started = ContinuousClock.now
        await store.ensureFolderZeroIndexReady()
        let elapsed = started.duration(to: .now)

        #expect(elapsed < .milliseconds(200))
        #expect(store.folderZeroItems.value?.count == 1)
    }

    @Test func `Automatic sync stays idle in UI when counts match`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: realIndex
        )

        try await realIndex.upsertLive(CollectionFixtures.sampleReleases[0], username: identity.username)
        let generation = try await realIndex.beginSyncGeneration(username: identity.username)
        try await realIndex.upsertSynced(
            [CollectionFixtures.sampleReleases[0]],
            username: identity.username,
            generation: generation
        )
        _ = try await realIndex.sweep(username: identity.username, keeping: generation)

        store.sync(with: .authenticated(identity))
        await store.ensureFolderZeroIndexReady()
        try await Task.sleep(for: .milliseconds(300))

        #expect(store.folderZeroSync == .idle)
    }

    @Test func `Background folder zero sync can run again after the first finishes`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setFolderZeroRemoteCount(1)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: realIndex
        )

        try await realIndex.upsertLive(CollectionFixtures.sampleReleases[0], username: identity.username)
        let generation = try await realIndex.beginSyncGeneration(username: identity.username)
        try await realIndex.upsertSynced(
            [CollectionFixtures.sampleReleases[0]],
            username: identity.username,
            generation: generation
        )
        _ = try await realIndex.sweep(username: identity.username, keeping: generation)

        store.sync(with: .authenticated(identity))
        await store.ensureFolderZeroIndexReady()
        try await Task.sleep(for: .milliseconds(400))

        let requestsAfterFirstBackgroundSync = await apiClient.requestCount

        await store.loadReleases(folderId: .zero)
        try await Task.sleep(for: .milliseconds(400))

        #expect(await apiClient.requestCount > requestsAfterFirstBackgroundSync)
    }

    @Test func `Local items load when network is unavailable`() async throws {
        let container = try TestModelContainer.make()
        let realIndex = CollectionLocalIndex(modelContainer: container)
        let fetcher = MockCollectionCachedFetcher()
        await fetcher.setShouldFail(true)
        let apiClient = MockCollectionNetworkClient()
        await apiClient.setShouldFail(true)
        let store = try CollectionStoreTestSupport.makeStore(
            fetcher: fetcher,
            apiClient: apiClient,
            localIndex: realIndex
        )

        try await realIndex.upsertLive(CollectionFixtures.sampleReleases[0], username: identity.username)
        store.sync(with: .authenticated(identity))
        await store.ensureFolderZeroIndexReady()

        #expect(store.folderZeroItems.value?.count == 1)
    }
}
