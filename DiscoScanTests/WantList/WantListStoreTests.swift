//
//  WantListStoreTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
struct WantListStoreTests {

    private let identity = DiscogsIdentity(
        id: 1,
        username: "tester",
        resourceURL: URL(string: "https://api.discogs.com/users/tester"),
        consumerName: "DiscoScan"
    )

    @Test func syncResetsOnLogout() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadWants()
        #expect(store.wants == .loaded(WantListFixtures.sampleWants))

        store.sync(with: .unauthenticated)
        #expect(store.wants == .idle)
    }

    @Test func syncResetsWhenUsernameChanges() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadWants()

        let otherIdentity = DiscogsIdentity(
            id: 2,
            username: "other",
            resourceURL: nil,
            consumerName: nil
        )
        store.sync(with: .authenticated(otherIdentity))
        #expect(store.wants == .idle)
    }

    @Test func loadWantsTransitionsToLoaded() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadWants()

        #expect(store.wants == .loaded(WantListFixtures.sampleWants))
        #expect(fetcher.lastFetch?.forceRefresh == false)
        #expect(fetcher.lastFetch?.key == "wants-page-1")
        #expect(fetcher.lastFetch?.userScope == "tester")
        #expect(store.canLoadMore())
    }

    @Test func loadWantsFailsWhenNotAuthenticated() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        await store.loadWants()

        if case .failed = store.wants {
            #expect(Bool(true))
        } else {
            Issue.record("Expected wants to fail when unauthenticated")
        }
    }

    @Test func loadWantsRefreshFailurePreservesStaleData() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadWants()
        fetcher.shouldFail = true
        await store.loadWants(forceRefresh: true)

        #expect(store.wants == .loaded(WantListFixtures.sampleWants))
    }

    @Test func deleteReleaseCallsEndpointAndRefreshes() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteRelease(releaseId: 1_867_708)

        #expect(apiClient.lastRequestPath?.contains("/wants/1867708") == true)
        #expect(fetcher.lastFetch?.forceRefresh == true)
        #expect(store.lastMutationError == nil)
    }

    @Test func addReleaseCallsEndpointAndRefreshes() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(releaseId: 249_504, notes: "Want this", rating: 5)

        #expect(apiClient.lastRequestPath?.contains("/wants/249504") == true)
        #expect(fetcher.lastFetch?.forceRefresh == true)
        #expect(store.lastMutationError == nil)
    }

    @Test func isInWantListReturnsTrueWhenLoaded() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadWants()

        #expect(store.isInWantList(releaseId: 1_867_708))
        #expect(store.isInWantList(releaseId: 999_999) == false)
    }

    @Test func isInWantListReturnsFalseWhenNotLoaded() {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        #expect(store.isInWantList(releaseId: 1_867_708) == false)
    }

    @Test func ensureWantsLoadedFetchesWhenIdle() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.ensureWantsLoaded()

        #expect(store.wants == .loaded(WantListFixtures.sampleWants))
        #expect(fetcher.fetchCount == 1)
    }

    @Test func editReleaseCallsEndpointAndRefreshes() async {
        let fetcher = MockWantListCachedFetcher()
        let apiClient = MockWantListNetworkClient()
        let store = WantListStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.editRelease(releaseId: 1_867_708, notes: "Updated", rating: 4)

        #expect(apiClient.lastRequestPath?.contains("/wants/1867708") == true)
        #expect(fetcher.lastFetch?.forceRefresh == true)
        #expect(store.lastMutationError == nil)
    }
}
