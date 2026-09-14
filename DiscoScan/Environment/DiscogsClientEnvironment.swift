//
//  DiscogsClientEnvironment.swift
//  DiscoScan
//

import NetworkKit
import SwiftUI

private actor UnimplementedCachedFetcher: CachedFetcherProtocol {
    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        fatalError("cachedFetcher environment value was not injected.")
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        nil
    }
}

extension EnvironmentValues {
    @Entry var cachedFetcher: any CachedFetcherProtocol = UnimplementedCachedFetcher()
}
