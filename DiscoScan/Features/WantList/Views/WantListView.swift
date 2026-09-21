//
//  WantListView.swift
//  DiscoScan
//

import SwiftUI

struct WantListView: View {

    @Environment(\.wantListStore) private var store
    @State private var isAnimating: Bool = true

    var body: some View {
        ResourceContainerView(
            state: store.wants,
            retry: { await store.loadWants(forceRefresh: true) }
        ) { wants in
            if wants.isEmpty {
                ContentUnavailableView(
                    "Want List",
                    systemImage: "heart",
                    description: Text("Your want list is empty.")
                )
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.breathe, options: .speed(10).repeat(2), isActive: isAnimating)

            } else {
                List {
                    ForEach(wants) { item in
                        NavigationLink(value: AppRoute.releaseDetail(id: item.id)) {
                            ReleaseSummaryRowView(information: item.basicInformation)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await store.deleteRelease(releaseId: item.id)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }

                    if store.canLoadMore() {
                        PaginationTrigger {
                            await store.loadMoreWants()
                        }
                    }
                }
            }
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
