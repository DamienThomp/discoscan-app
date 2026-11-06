//
//  SearchStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

@MainActor
@Observable
private final class UnimplementedSearchStore: SearchStoreProtocol {
    private(set) var recentQueries: [String] = []

    func results(for context: SearchContext) -> ResourceState<SearchResponse> {
        fatalError("searchStore environment value was not injected.")
    }

    func search(_ context: SearchContext, forceRefresh: Bool) async {
        fatalError("searchStore environment value was not injected.")
    }

    func recordRecentQuery(_ query: String) {
        fatalError("searchStore environment value was not injected.")
    }

    func removeRecentQuery(_ query: String) {
        fatalError("searchStore environment value was not injected.")
    }

    func removeRecentQueries(_ queries: [String]) {
        fatalError("searchStore environment value was not injected.")
    }

    func clearRecentQueries() {
        fatalError("searchStore environment value was not injected.")
    }
}

private let unimplementedSearchStore = UnimplementedSearchStore()

extension EnvironmentValues {
    @Entry var searchStore: any SearchStoreProtocol = unimplementedSearchStore
}
