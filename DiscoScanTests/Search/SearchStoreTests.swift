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
        #expect(fetcher.fetchCount == 1)
    }

    @Test func searchUsesCorrectCacheKeyAndScope() async {
        let (store, fetcher, _) = makeSearchStore()
        let context = SearchContext.barcode(code: "042283923518")

        await store.search(context)

        #expect(fetcher.lastFetch?.key == context.cacheKey)
        #expect(fetcher.lastFetch?.scope == .search)
        #expect(fetcher.lastFetch?.forceRefresh == false)
    }

    @Test func searchFailsSetsFailedState() async {
        let fetcher = MockSearchCachedFetcher()
        fetcher.shouldFail = true
        let (store, _) = makeSearchStore(fetcher: fetcher)

        await store.search(.text(query: "test"))

        if case .failed = store.results(for: .text(query: "test")) {
            #expect(Bool(true))
        } else {
            Issue.record("Expected search to fail")
        }
    }

    @Test func searchRefreshFailurePreservesStaleResults() async {
        let fetcher = MockSearchCachedFetcher()
        let (store, _) = makeSearchStore(fetcher: fetcher)
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)
        fetcher.shouldFail = true
        await store.search(context, forceRefresh: true)

        #expect(store.results(for: context) == .loaded(SearchTestFixtures.sampleResponse))
    }

    @Test func searchForceRefreshRefetches() async {
        let (store, fetcher, _) = makeSearchStore()
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)
        await store.search(context, forceRefresh: true)

        #expect(fetcher.fetchCount == 2)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func `recordRecentQuery prepends and dedupes case insensitively`() {
        let (store, persistence) = makeSearchStore()
        store.recordRecentQuery("Kind of Blue")
        store.recordRecentQuery("Bitches Brew")
        store.recordRecentQuery("kind of blue")

        #expect(store.recentQueries == ["kind of blue", "Bitches Brew"])
        #expect(persistence.savedQueries == store.recentQueries)
    }

    @Test func `recordRecentQuery ignores empty query`() {
        let (store, _) = makeSearchStore()
        store.recordRecentQuery("   ")
        #expect(store.recentQueries.isEmpty)
    }

    @Test func `removeRecentQuery deletes case insensitively`() {
        let (store, persistence) = makeSearchStore()
        store.recordRecentQuery("Kind of Blue")
        store.recordRecentQuery("Bitches Brew")
        store.removeRecentQuery("kind of blue")

        #expect(store.recentQueries == ["Bitches Brew"])
        #expect(persistence.savedQueries == ["Bitches Brew"])
    }

    @Test func `clearRecentQueries removes all`() {
        let (store, persistence) = makeSearchStore()
        store.recordRecentQuery("Kind of Blue")
        store.clearRecentQueries()

        #expect(store.recentQueries.isEmpty)
        #expect(persistence.savedQueries.isEmpty)
    }

    @Test func `recordRecentQuery truncates at ten`() {
        let (store, persistence) = makeSearchStore()
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
        let (store, persistence) = makeSearchStore()
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

final class InMemoryRecentSearchPersistence: RecentSearchPersistence, @unchecked Sendable {
    private(set) var savedQueries: [String] = []
    private(set) var saveCallCount = 0

    func load() -> [String] { savedQueries }

    func save(_ queries: [String]) {
        savedQueries = queries
        saveCallCount += 1
    }

    func seedForLoad(_ queries: [String]) {
        savedQueries = queries
    }
}

enum SearchTestFixtures {
    static let sampleResponse = SearchResponse(
        pagination: SearchPagination(page: 1, pages: 1, perPage: 25, items: 1),
        results: [
            SearchResult(id: 1, type: "release", title: "Test Release")
        ]
    )
}

final class MockSearchCachedFetcher: CachedFetcherProtocol, @unchecked Sendable {
    private(set) var lastFetch: MockSearchFetchRecord?
    private(set) var fetchCount = 0
    var shouldFail = false

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        forceRefresh: Bool
    ) async throws -> E.Response {
        fetchCount += 1
        lastFetch = MockSearchFetchRecord(key: key, scope: scope, forceRefresh: forceRefresh)

        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }

        if endpoint is SearchEndpoint {
            guard let response = SearchTestFixtures.sampleResponse as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        throw URLError(.unsupportedURL)
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String
    ) async throws -> E.Response? {
        nil
    }

    func invalidate(key: String) async {}

    func invalidateKeys(matchingPrefix prefix: String) async {}
}

struct MockSearchFetchRecord: Sendable {
    let key: String
    let scope: CacheScope
    let forceRefresh: Bool
}
