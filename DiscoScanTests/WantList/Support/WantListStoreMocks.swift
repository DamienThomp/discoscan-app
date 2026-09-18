//
//  WantListStoreMocks.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
@testable import DiscoScan

final class MockWantListCachedFetcher: CachedFetcherProtocol, @unchecked Sendable {
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

        if endpoint is WantListEndpoint {
            guard let response = WantListFixtures.sampleResponse as? E.Response else {
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

final class MockWantListNetworkClient: NetworkManagerProtocol, @unchecked Sendable {
    private(set) var lastRequestPath: String?
    private(set) var requestCount = 0

    func request<E>(for endpoint: E) async throws -> E.Response where E: EndpointProtocol {
        requestCount += 1
        lastRequestPath = endpoint.path

        if E.Response.self == EmptyResponse.self {
            guard let response = EmptyResponse() as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        if E.Response.self == WantListItem.self {
            guard let response = WantListFixtures.sampleWants.first as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        throw URLError(.unsupportedURL)
    }

    func requestData<E>(for endpoint: E) async throws -> Data where E: EndpointProtocol {
        throw URLError(.unsupportedURL)
    }

    func response<E>(for endpoint: E) async throws -> NetworkResponse<E.Response> where E: EndpointProtocol {
        throw URLError(.unsupportedURL)
    }

    func responseData<E>(for endpoint: E) async throws -> NetworkResponse<Data> where E: EndpointProtocol {
        throw URLError(.unsupportedURL)
    }
}
