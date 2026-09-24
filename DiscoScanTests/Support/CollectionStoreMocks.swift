//
//  CollectionStoreMocks.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
@testable import DiscoScan

struct MockFetchRecord: Sendable {
    let key: String
    let forceRefresh: Bool
}

final class MockCollectionCachedFetcher: CachedFetcherProtocol, @unchecked Sendable {
    private(set) var lastFetch: MockFetchRecord?
    private(set) var fetchCount = 0
    private(set) var lastInvalidatedKey: String?
    private(set) var lastInvalidatedPrefix: String?
    var shouldFail = false
    var delayNanoseconds: UInt64 = 0

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        forceRefresh: Bool
    ) async throws -> E.Response {
        fetchCount += 1
        lastFetch = MockFetchRecord(key: key, forceRefresh: forceRefresh)

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }

        if endpoint is CollectionFoldersEndpoint {
            guard let response = CollectionFixtures.sampleFoldersResponse as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        if endpoint is CollectionItemsByFolderEndpoint {
            guard let response = CollectionFixtures.sampleReleasesResponse as? E.Response else {
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

    func invalidate(key: String) async {
        lastInvalidatedKey = key
    }

    func invalidateKeys(matchingPrefix prefix: String) async {
        lastInvalidatedPrefix = prefix
    }
}

final class MockCollectionNetworkClient: NetworkManagerProtocol, @unchecked Sendable {
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

        if E.Response.self == CollectionFolderResponse.self {
            guard let response = CollectionFolderResponse(
                id: 3,
                count: 0,
                name: "New Folder",
                resourceUrl: "https://example.com/3"
            ) as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        if E.Response.self == AddReleaseToCollectionResponse.self {
            guard let response = AddReleaseToCollectionResponse(
                instanceId: 2000,
                resourceURL: nil
            ) as? E.Response else {
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
