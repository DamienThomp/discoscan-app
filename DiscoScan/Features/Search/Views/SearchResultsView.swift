//
//  SearchResultsView.swift
//  DiscoScan
//

import SwiftUI

struct SearchResultsView: View {
    @Environment(\.searchStore) private var searchStore
    @Environment(AppRouter.self) private var router

    let context: SearchContext

    var body: some View {
        ResourceContainerView(
            state: searchStore.results(for: context),
            retry: { await searchStore.search(context, forceRefresh: true) }
        ) { response in
            SearchResultsContent(context: context, response: response)
        }
        .navigationTitle(context.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await searchStore.search(context)
        }
        .refreshable {
            await searchStore.search(context, forceRefresh: true)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack {
        SearchResultsView(context: .text(query: "Kind of Blue"))
            .environment(\.searchStore, previewSearchStore(.loaded(context: .text(query: "Kind of Blue"))))
            .environment(AppRouter())
    }
}

#Preview("Failed") {
    NavigationStack {
        SearchResultsView(context: .text(query: "missing"))
            .environment(
                \.searchStore,
                previewSearchStore(.failed(context: .text(query: "missing"), message: "Could not search Discogs."))
            )
            .environment(AppRouter())
    }
}
#endif
