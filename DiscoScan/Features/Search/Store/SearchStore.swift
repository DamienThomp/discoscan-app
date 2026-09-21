//
//  SearchStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

@MainActor
@Observable
final class SearchStore: SearchStoreProtocol {

    private(set) var resultsByContext: [SearchContext: ResourceState<SearchResponse>] = [:]

    private let cachedFetcher: any CachedFetcherProtocol

    init(cachedFetcher: any CachedFetcherProtocol) {
        self.cachedFetcher = cachedFetcher
    }

    func results(for context: SearchContext) -> ResourceState<SearchResponse> {
        resultsByContext[context] ?? .idle
    }

    func search(_ context: SearchContext, forceRefresh: Bool = false) async {
        if !forceRefresh, case .loaded = resultsByContext[context] {
            return
        }

        let current = resultsByContext[context] ?? .idle
        resultsByContext[context] = current.beginRefresh()

        do {
            let response = try await cachedFetcher.fetch(
                context.endpoint,
                key: context.cacheKey,
                scope: .search,
                userScope: nil,
                forceRefresh: forceRefresh
            )
            resultsByContext[context] = .loaded(response)
        } catch {
            let inFlight = resultsByContext[context] ?? .idle
            resultsByContext[context] = inFlight.recoverFromFetchFailure(error.localizedDescription)
        }
    }
}
