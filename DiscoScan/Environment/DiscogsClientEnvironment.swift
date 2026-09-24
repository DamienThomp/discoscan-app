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
        forceRefresh: Bool
    ) async throws -> E.Response {
        fatalError("cachedFetcher environment value was not injected.")
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String
    ) async throws -> E.Response? {
        nil
    }

    func invalidate(key: String) async {
        fatalError("cachedFetcher environment value was not injected.")
    }

    func invalidateKeys(matchingPrefix prefix: String) async {
        fatalError("cachedFetcher environment value was not injected.")
    }
}

extension EnvironmentValues {
    @Entry var cachedFetcher: any CachedFetcherProtocol = UnimplementedCachedFetcher()
}
