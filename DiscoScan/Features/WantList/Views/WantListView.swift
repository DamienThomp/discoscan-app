//
//  WantListView.swift
//  DiscoScan
//

import SwiftUI

struct WantListView: View {

    @Environment(\.wantListStore) private var store

    private var emptyState: AnimatedEmptyStateView.Configuration {
        .init(
            title: "Want List",
            systemImage: "heart",
            description: "Your want list is empty.",
            effect: .breathe
        )
    }

    var body: some View {
        ResourceContainerView(
            state: store.wants,
            retry: { await store.refreshWants() }
        ) { wants in
            PaginatedReleaseListView(
                items: wants,
                emptyState: emptyState,
                canLoadMore: store.canLoadMore(),
                loadMore: { await store.loadMoreWants() },
                delete: { item in
                    await store.deleteRelease(releaseId: item.releaseId)
                }
            )
        }
        .task {
            if store.wants == .idle {
                await store.loadWants()
            }
        }
        .refreshable {
            await store.refreshWants()
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    PreviewAppRouteStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsLoaded))
}

#Preview("Empty") {
    PreviewAppRouteStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsEmpty))
}

#Preview("Failed") {
    PreviewAppRouteStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsFailed("Could not load want list.")))
}

#Preview("Loading") {
    PreviewAppRouteStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsLoading))
}
#endif
