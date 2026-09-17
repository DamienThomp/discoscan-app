//
//  WantListView.swift
//  DiscoScan
//

import SwiftUI

struct WantListView: View {

    @Environment(\.wantListStore) private var store
    @Environment(AppRouter.self) private var router

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
            } else {
                List(wants) { item in
                    Text(item.basicInformation.title)
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
    NavigationStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsLoaded))
    .environment(AppRouter())
}

#Preview("Empty") {
    NavigationStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsEmpty))
}

#Preview("Failed") {
    NavigationStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsFailed("Could not load want list.")))
}

#Preview("Loading") {
    NavigationStack {
        WantListView()
    }
    .environment(\.wantListStore, previewWantListStore(.wantsLoading))
}
#endif
