//
//  PreviewWantListCachedFetcher.swift
//  DiscoScan
//

#if DEBUG
import NetworkKit

actor PreviewEmptyWantListCachedFetcher: CachedFetcherProtocol {
    private static let emptyResponse = WantListResponse(
        pagination: SearchPagination(page: 1, pages: 1, perPage: 50, items: 0),
        wants: []
    )

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        guard let response = Self.emptyResponse as? E.Response else {
            preconditionFailure("Unexpected preview endpoint response type: \(E.Response.self)")
        }
        return response
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        nil
    }
}
#endif
