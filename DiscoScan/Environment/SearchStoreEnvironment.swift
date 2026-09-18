//
//  SearchStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

@MainActor
@Observable
private final class UnimplementedSearchStore: SearchStoreProtocol {
    func results(for context: SearchContext) -> ResourceState<SearchResponse> {
        fatalError("searchStore environment value was not injected.")
    }

    func search(_ context: SearchContext, forceRefresh: Bool) async {
        fatalError("searchStore environment value was not injected.")
    }
}

private let unimplementedSearchStore = UnimplementedSearchStore()

extension EnvironmentValues {
    @Entry var searchStore: any SearchStoreProtocol = unimplementedSearchStore
}
