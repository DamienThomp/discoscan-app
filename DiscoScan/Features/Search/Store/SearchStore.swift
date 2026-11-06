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

    private static let recentQueryLimit = 10

    private(set) var resultsByContext: [SearchContext: ResourceState<SearchResponse>] = [:]
    private(set) var recentQueries: [String] = []

    private let cachedFetcher: any CachedFetcherProtocol
    private let recentSearchPersistence: any RecentSearchPersistence

    init(
        cachedFetcher: any CachedFetcherProtocol,
        recentSearchPersistence: any RecentSearchPersistence
    ) {
        self.cachedFetcher = cachedFetcher
        self.recentSearchPersistence = recentSearchPersistence
        self.recentQueries = recentSearchPersistence.load()
    }

    convenience init(dependencies: AppDependencies) {
        self.init(
            cachedFetcher: dependencies.cachedFetcher,
            recentSearchPersistence: dependencies.recentSearchPersistence
        )
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
                forceRefresh: forceRefresh
            )
            resultsByContext[context] = .loaded(response)
        } catch {
            let inFlight = resultsByContext[context] ?? .idle
            resultsByContext[context] = inFlight.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func recordRecentQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = recentQueries.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        if updated.count > Self.recentQueryLimit {
            updated = Array(updated.prefix(Self.recentQueryLimit))
        }
        recentQueries = updated
        recentSearchPersistence.save(updated)
    }

    func removeRecentQuery(_ query: String) {
        removeRecentQueries([query])
    }

    func removeRecentQueries(_ queries: [String]) {
        let trimmedTargets = Set(
            queries
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        guard !trimmedTargets.isEmpty else { return }

        let updated = recentQueries.filter { stored in
            !trimmedTargets.contains { stored.caseInsensitiveCompare($0) == .orderedSame }
        }
        guard updated.count != recentQueries.count else { return }
        recentQueries = updated
        recentSearchPersistence.save(updated)
    }

    func clearRecentQueries() {
        guard !recentQueries.isEmpty else { return }
        recentQueries = []
        recentSearchPersistence.save([])
    }
}
