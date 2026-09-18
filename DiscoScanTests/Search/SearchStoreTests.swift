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
        let fetcher = MockSearchCachedFetcher()
        let store = SearchStore(cachedFetcher: fetcher)
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)

        #expect(store.results(for: context) == .loaded(SearchTestFixtures.sampleResponse))
        #expect(fetcher.fetchCount == 1)
    }

    @Test func searchUsesCorrectCacheKeyAndScope() async {
        let fetcher = MockSearchCachedFetcher()
        let store = SearchStore(cachedFetcher: fetcher)
        let context = SearchContext.barcode(code: "042283923518")

        await store.search(context)

        #expect(fetcher.lastFetch?.key == context.cacheKey)
        #expect(fetcher.lastFetch?.scope == .search)
        #expect(fetcher.lastFetch?.forceRefresh == false)
    }

    @Test func searchFailsSetsFailedState() async {
        let fetcher = MockSearchCachedFetcher()
        fetcher.shouldFail = true
        let store = SearchStore(cachedFetcher: fetcher)

        await store.search(.text(query: "test"))

        if case .failed = store.results(for: .text(query: "test")) {
            #expect(Bool(true))
        } else {
            Issue.record("Expected search to fail")
        }
    }

    @Test func searchForceRefreshRefetches() async {
        let fetcher = MockSearchCachedFetcher()
        let store = SearchStore(cachedFetcher: fetcher)
        let context = SearchContext.text(query: "Nirvana")

        await store.search(context)
        await store.search(context, forceRefresh: true)

        #expect(fetcher.fetchCount == 2)
        #expect(fetcher.lastFetch?.forceRefresh == true)
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
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        fetchCount += 1
        lastFetch = MockSearchFetchRecord(key: key, scope: scope, forceRefresh: forceRefresh, userScope: userScope)

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
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        nil
    }
}

struct MockSearchFetchRecord: Sendable {
    let key: String
    let scope: CacheScope
    let forceRefresh: Bool
    let userScope: String?
}
