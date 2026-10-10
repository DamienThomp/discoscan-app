//
//  CollectionListView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionListView: View {

    let folderId: Int
    let folderName: String

    @Environment(\.collectionStore) private var store

    @State private var searchText = ""
    @State private var deleteErrorMessage: String?

    private var isFolderZero: Bool { folderId == .zero }

    private var displayedItems: [CollectionReleaseItem] {
        guard isFolderZero else {
            return store.releasesState(for: folderId).value ?? []
        }
        return store.searchFolderZero(query: searchText)
    }

    private var emptyState: AnimatedEmptyStateView.Configuration {
        let description: String = if isFolderZero && !searchText.isEmpty {
            "No matching releases in your collection."
        } else if isFolderZero {
            "Your collection is empty."
        } else {
            "This folder is empty."
        }

        return .init(
            title: "Collection",
            systemImage: "square.stack",
            description: description,
            effect: .bounceDown
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if isFolderZero {
                CollectionSyncBanner(phase: store.folderZeroSync)
            }

            ResourceContainerView(
                state: store.releasesState(for: folderId),
                retry: { await store.refreshReleases(folderId: folderId) }
            ) { _ in
                PaginatedReleaseListView(
                    items: displayedItems,
                    emptyState: emptyState,
                    canLoadMore: store.canLoadMore(folderId: folderId),
                    loadMore: { await store.loadMoreReleases(folderId: folderId) },
                    delete: { item in
                        await store.deleteRelease(
                            from: item.folderId,
                            releaseId: item.releaseId,
                            instanceId: item.instanceId
                        )
                        if let message = store.lastMutationError {
                            deleteErrorMessage = message
                        }
                    }
                )
            }
        }
        .mutationErrorAlert(
            title: "Could Not Remove Release",
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            ),
            message: deleteErrorMessage
        )
        .navigationTitle(folderName)
        .if(isFolderZero) { view in
            view.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search your collection…")
        }
        .task { await store.loadReleases(folderId: folderId) }
        .refreshable { await store.refreshReleases(folderId: folderId) }
    }
}

#if DEBUG
#Preview("Loaded") {
    PreviewAppRouteStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
            .environment(\.collectionStore, previewCollectionStore(.releasesLoaded(folderId: 1)))
    }
}

#Preview("Folder Zero Loaded") {
    PreviewAppRouteStack {
        CollectionListView(folderId: .zero, folderName: "All")
    }
    .environment(\.collectionStore, previewCollectionStore(.folderZeroLoaded))
}

#Preview("Empty") {
    PreviewAppRouteStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesEmpty(folderId: 1)))
}

#Preview("Failed") {
    PreviewAppRouteStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesFailed(folderId: 1, message: "Could not load releases.")))
}

#Preview("Loading") {
    PreviewAppRouteStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesLoading(folderId: 1)))
}
#endif
