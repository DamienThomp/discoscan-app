//
//  SearchStoreTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
struct SearchStoreTests {

    @Test func searchTransitionsToLoaded() async {
        let (store, fetcher, _) = makeSearchStore()
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)

        #expect(store.results(for: context) == .loaded(SearchTestFixtures.sampleResponse))
        #expect(await fetcher.fetchCount == 1)
    }

    @Test func searchUsesCorrectCacheKeyAndScope() async {
        let (store, fetcher, _) = makeSearchStore()
        let context = SearchContext.barcode(code: "042283923518")

        await store.search(context)

        #expect(await fetcher.lastFetch?.key == context.cacheKey)
        #expect(await fetcher.lastFetch?.scope == .search)
        #expect(await fetcher.lastFetch?.forceRefresh == false)
    }

    @Test func searchFailsSetsFailedState() async {
        let fetcher = MockSearchCachedFetcher()
        await fetcher.setShouldFail(true)
        let (store, _, _) = makeSearchStore(fetcher: fetcher)

        await store.search(.text(query: "test"))

        if case .failed = store.results(for: .text(query: "test")) {
            #expect(Bool(true))
        } else {
            Issue.record("Expected search to fail")
        }
    }

    @Test func searchRefreshFailurePreservesStaleResults() async {
        let fetcher = MockSearchCachedFetcher()
        let (store, _, _) = makeSearchStore(fetcher: fetcher)
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)
        await fetcher.setShouldFail(true)
        await store.search(context, forceRefresh: true)

        #expect(store.results(for: context) == .loaded(SearchTestFixtures.sampleResponse))
    }

    @Test func searchForceRefreshRefetches() async {
        let (store, fetcher, _) = makeSearchStore()
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)
        await store.search(context, forceRefresh: true)

        #expect(await fetcher.fetchCount == 2)
        #expect(await fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func `recordRecentQuery prepends and dedupes case insensitively`() {
        let (store, _, persistence) = makeSearchStore()
        store.recordRecentQuery("Kind of Blue")
        store.recordRecentQuery("Bitches Brew")
        store.recordRecentQuery("kind of blue")

        #expect(store.recentQueries == ["kind of blue", "Bitches Brew"])
        #expect(persistence.savedQueries == store.recentQueries)
    }

    @Test func `recordRecentQuery ignores empty query`() {
        let (store, _, _) = makeSearchStore()
        store.recordRecentQuery("   ")
        #expect(store.recentQueries.isEmpty)
    }

    @Test func `removeRecentQuery deletes case insensitively`() {
        let (store, _, persistence) = makeSearchStore()
        store.recordRecentQuery("Kind of Blue")
        store.recordRecentQuery("Bitches Brew")
        store.removeRecentQuery("kind of blue")

        #expect(store.recentQueries == ["Bitches Brew"])
        #expect(persistence.savedQueries == ["Bitches Brew"])
    }

    @Test func `clearRecentQueries removes all`() {
        let (store, _, persistence) = makeSearchStore()
        store.recordRecentQuery("Kind of Blue")
        store.clearRecentQueries()

        #expect(store.recentQueries.isEmpty)
        #expect(persistence.savedQueries.isEmpty)
    }

    @Test func `recordRecentQuery truncates at ten`() {
        let (store, _, persistence) = makeSearchStore()
        for index in 0..<12 {
            store.recordRecentQuery("Query \(index)")
        }
        #expect(store.recentQueries.count == 10)
        #expect(store.recentQueries.first == "Query 11")
        #expect(store.recentQueries.last == "Query 2")
        #expect(persistence.savedQueries.count == 10)
    }

    @Test func `init loads recentQueries from persistence`() {
        let persistence = InMemoryRecentSearchPersistence()
        persistence.seedForLoad(["Kind of Blue", "Bitches Brew"])
        let store = SearchStore(cachedFetcher: MockSearchCachedFetcher(), recentSearchPersistence: persistence)
        #expect(store.recentQueries == ["Kind of Blue", "Bitches Brew"])
    }

    @Test func `removeRecentQueries batch deletes multiple with one save`() {
        let (store, _, persistence) = makeSearchStore()
        store.recordRecentQuery("A")
        store.recordRecentQuery("B")
        store.recordRecentQuery("C")
        let savesBeforeBatch = persistence.saveCallCount
        store.removeRecentQueries(["A", "C"])
        #expect(store.recentQueries == ["B"])
        #expect(persistence.savedQueries == ["B"])
        #expect(persistence.saveCallCount == savesBeforeBatch + 1)
    }
}

@MainActor
private func makeSearchStore(
    fetcher: MockSearchCachedFetcher = MockSearchCachedFetcher(),
    persistence: InMemoryRecentSearchPersistence = InMemoryRecentSearchPersistence()
) -> (SearchStore, MockSearchCachedFetcher, InMemoryRecentSearchPersistence) {
    let store = SearchStore(cachedFetcher: fetcher, recentSearchPersistence: persistence)
    return (store, fetcher, persistence)
}

struct InMemoryRecentSearchPersistence: RecentSearchPersistence, Sendable {
    private struct State: Sendable {
        var savedQueries: [String] = []
        var saveCallCount = 0
    }

    private let state = Locked(State())

    var savedQueries: [String] {
        state.withLock { $0.savedQueries }
    }

    var saveCallCount: Int {
        state.withLock { $0.saveCallCount }
    }

    func load() -> [String] { savedQueries }

    func save(_ queries: [String]) {
        state.withLock {
            $0.savedQueries = queries
            $0.saveCallCount += 1
        }
    }

    func seedForLoad(_ queries: [String]) {
        state.withLock { $0.savedQueries = queries }
    }
}
