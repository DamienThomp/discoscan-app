//
//  ProfileStoreTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

@MainActor
struct ProfileStoreTests {

    private let identity = DiscogsIdentity(
        id: 1,
        username: "tester",
        resourceURL: URL(string: "https://api.discogs.com/users/tester"),
        consumerName: "DiscoScan"
    )

    @Test func syncResetsOnLogout() async {
        let fetcher = MockProfileCachedFetcher()
        let store = ProfileStore(cachedFetcher: fetcher)

        store.sync(with: .authenticated(identity))
        await store.loadProfile()
        #expect(store.profile == .loaded(ProfileTestFixtures.sampleProfile))

        store.sync(with: .unauthenticated)
        #expect(store.profile == .idle)
    }

    @Test func syncResetsWhenUsernameChanges() async {
        let fetcher = MockProfileCachedFetcher()
        let store = ProfileStore(cachedFetcher: fetcher)

        store.sync(with: .authenticated(identity))
        await store.loadProfile()

        let otherIdentity = DiscogsIdentity(
            id: 2,
            username: "other",
            resourceURL: nil,
            consumerName: nil
        )
        store.sync(with: .authenticated(otherIdentity))
        #expect(store.profile == .idle)
    }

    @Test func loadProfileTransitionsToLoaded() async {
        let fetcher = MockProfileCachedFetcher()
        let store = ProfileStore(cachedFetcher: fetcher)

        store.sync(with: .authenticated(identity))
        await store.loadProfile()

        #expect(store.profile == .loaded(ProfileTestFixtures.sampleProfile))
        #expect(fetcher.fetchCount == 1)
    }

    @Test func loadProfileUsesCorrectCacheKeyAndScope() async {
        let fetcher = MockProfileCachedFetcher()
        let store = ProfileStore(cachedFetcher: fetcher)

        store.sync(with: .authenticated(identity))
        await store.loadProfile()

        #expect(fetcher.lastFetch?.key == "userProfile")
        #expect(fetcher.lastFetch?.forceRefresh == false)
    }

    @Test func loadProfileFailsWhenUnauthenticated() async {
        let fetcher = MockProfileCachedFetcher()
        let store = ProfileStore(cachedFetcher: fetcher)

        await store.loadProfile()

        if case .failed = store.profile {
            #expect(Bool(true))
        } else {
            Issue.record("Expected profile to fail when unauthenticated")
        }
        #expect(fetcher.fetchCount == 0)
    }

    @Test func loadProfileFailsSetsFailedState() async {
        let fetcher = MockProfileCachedFetcher()
        fetcher.shouldFail = true
        let store = ProfileStore(cachedFetcher: fetcher)

        store.sync(with: .authenticated(identity))
        await store.loadProfile()

        if case .failed = store.profile {
            #expect(Bool(true))
        } else {
            Issue.record("Expected profile to fail")
        }
    }
}
