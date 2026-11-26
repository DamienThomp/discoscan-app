//
//  SearchStoreMocks.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
@testable import DiscoScan

enum SearchTestFixtures {
    static let sampleResponse = SearchResponse(
        pagination: SearchPagination(page: 1, pages: 1, perPage: 25, items: 1),
        results: [
            SearchResult(id: 1, type: "release", title: "Test Release")
        ]
    )
}

actor MockSearchCachedFetcher: CachedFetcherProtocol {
    private(set) var lastFetch: MockSearchFetchRecord?
    private(set) var fetchCount = 0
    var shouldFail = false

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

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

    func clearAll() async {}
}

struct MockSearchFetchRecord: Sendable {
    let key: String
    let scope: CacheScope
    let forceRefresh: Bool
}
