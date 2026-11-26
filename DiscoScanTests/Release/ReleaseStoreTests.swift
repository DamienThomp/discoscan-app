//
//  ReleaseStoreTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

@MainActor
struct ReleaseStoreTests {

    @Test func loadReleaseTransitionsToLoaded() async {
        let fetcher = MockReleaseCachedFetcher()
        let store = ReleaseStore(cachedFetcher: fetcher)

        await store.loadRelease(id: 249_504)

        #expect(store.detail(for: 249_504) == .loaded(ReleaseTestFixtures.sampleRelease))
        #expect(await fetcher.fetchCount == 1)
    }

    @Test func loadReleaseUsesCorrectCacheKeyAndScope() async {
        let fetcher = MockReleaseCachedFetcher()
        let store = ReleaseStore(cachedFetcher: fetcher)

        await store.loadRelease(id: 249_504)

        #expect(await fetcher.lastFetch?.key == "release-249504")
        #expect(await fetcher.lastFetch?.forceRefresh == false)
    }

    @Test func loadReleaseFailsSetsFailedState() async {
        let fetcher = MockReleaseCachedFetcher()
        await fetcher.setShouldFail(true)
        let store = ReleaseStore(cachedFetcher: fetcher)

        await store.loadRelease(id: 249_504)

        if case .failed = store.detail(for: 249_504) {
            #expect(Bool(true))
        } else {
            Issue.record("Expected release detail to fail")
        }
    }

    @Test func loadReleaseSkipsRefetchWhenAlreadyLoaded() async {
        let fetcher = MockReleaseCachedFetcher()
        let store = ReleaseStore(cachedFetcher: fetcher)

        await store.loadRelease(id: 249_504)
        await store.loadRelease(id: 249_504)

        #expect(await fetcher.fetchCount == 1)
    }

    @Test func loadReleaseRefreshFailurePreservesStaleDetail() async {
        let fetcher = MockReleaseCachedFetcher()
        let store = ReleaseStore(cachedFetcher: fetcher)

        await store.loadRelease(id: 249_504)
        await fetcher.setShouldFail(true)
        await store.loadRelease(id: 249_504, forceRefresh: true)

        #expect(store.detail(for: 249_504) == .loaded(ReleaseTestFixtures.sampleRelease))
    }

    @Test func loadReleaseForceRefreshRefetches() async {
        let fetcher = MockReleaseCachedFetcher()
        let store = ReleaseStore(cachedFetcher: fetcher)

        await store.loadRelease(id: 249_504)
        await store.loadRelease(id: 249_504, forceRefresh: true)

        #expect(await fetcher.fetchCount == 2)
        #expect(await fetcher.lastFetch?.forceRefresh == true)
    }
}
