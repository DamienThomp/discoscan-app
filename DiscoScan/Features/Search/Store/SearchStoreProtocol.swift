//
//  SearchStoreProtocol.swift
//  DiscoScan
//

import Foundation
import Observation

@MainActor
protocol SearchStoreProtocol: AnyObject, Observable {
    var recentQueries: [String] { get }

    func results(for context: SearchContext) -> ResourceState<SearchResponse>
    func search(_ context: SearchContext, forceRefresh: Bool) async

    func recordRecentQuery(_ query: String)
    func removeRecentQuery(_ query: String)
    func removeRecentQueries(_ queries: [String])
    func clearRecentQueries()
}

extension SearchStoreProtocol {
    func search(_ context: SearchContext) async {
        await search(context, forceRefresh: false)
    }
}
