//
//  PreviewSearchStore.swift
//  DiscoScan
//

#if DEBUG
import Foundation
import Observation

enum PreviewSearchStoreScenario {
    case loaded(context: SearchContext)
    case loading(context: SearchContext)
    case failed(context: SearchContext, message: String)
}

@MainActor
@Observable
final class PreviewSearchStore: SearchStoreProtocol {
    private(set) var resultsByContext: [SearchContext: ResourceState<SearchResponse>] = [:]

    init(scenario: PreviewSearchStoreScenario) {
        switch scenario {
        case .loaded(let context):
            resultsByContext[context] = .loaded(SearchFixtures.sampleResponse)
        case .loading(let context):
            resultsByContext[context] = .loading
        case .failed(let context, let message):
            resultsByContext[context] = .failed(message)
        }
    }

    func results(for context: SearchContext) -> ResourceState<SearchResponse> {
        resultsByContext[context] ?? .idle
    }

    func search(_ context: SearchContext, forceRefresh: Bool) async {}
}

enum SearchFixtures {
    static let sampleResponse = SearchResponse(
        pagination: SearchPagination(page: 1, pages: 1, perPage: 25, items: 1),
        results: [
            SearchResult(
                id: 249_504,
                type: "release",
                title: "Rick Astley - Never Gonna Give You Up",
                thumb: nil,
                resourceURL: URL(string: "https://api.discogs.com/releases/249504")
            )
        ]
    )
}

@MainActor
func previewSearchStore(_ scenario: PreviewSearchStoreScenario) -> any SearchStoreProtocol {
    PreviewSearchStore(scenario: scenario)
}
#endif
