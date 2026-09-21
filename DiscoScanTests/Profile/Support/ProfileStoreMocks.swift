//
//  ProfileStoreMocks.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
@testable import DiscoScan

enum ProfileTestFixtures {
    static let sampleProfile = ProfileFixtures.sample
}

final class MockProfileCachedFetcher: CachedFetcherProtocol, @unchecked Sendable {
    private(set) var lastFetch: MockFetchRecord?
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
        lastFetch = MockFetchRecord(key: key, forceRefresh: forceRefresh, userScope: userScope)

        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }

        if endpoint is UserProfileEndpoint {
            guard let response = ProfileTestFixtures.sampleProfile as? E.Response else {
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
