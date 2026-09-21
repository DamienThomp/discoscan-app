//
//  WantListView.swift
//  DiscoScan
//

import SwiftUI

struct WantListView: View {

    @Environment(\.wantListStore) private var store

    var body: some View {
        ResourceContainerView(
            state: store.wants,
            retry: { await store.loadWants(forceRefresh: true) }
        ) { wants in
            PaginatedReleaseListView(
                items: wants,
                emptyState: .init(
                    title: "Want List",
                    systemImage: "heart",
                    description: "Your want list is empty.",
                    effect: .breathe
                ),
                releaseID: { $0.id },
                basicInformation: { $0.basicInformation },
                canLoadMore: store.canLoadMore(),
                loadMore: { await store.loadMoreWants() },
                delete: { item in
                    await store.deleteRelease(releaseId: item.id)
                }
            )
        }
        .task {
            if store.wants == .idle {
                await store.loadWants()
            }
        }
        .refreshable {
            await store.loadWants(forceRefresh: true)
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
