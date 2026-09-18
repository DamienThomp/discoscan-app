//
//  SearchStoreProtocol.swift
//  DiscoScan
//

import Foundation
import Observation

@MainActor
protocol SearchStoreProtocol: AnyObject, Observable {
    func results(for context: SearchContext) -> ResourceState<SearchResponse>
    func search(_ context: SearchContext, forceRefresh: Bool) async
}

extension SearchStoreProtocol {
    func search(_ context: SearchContext) async {
        await search(context, forceRefresh: false)
    }
}
