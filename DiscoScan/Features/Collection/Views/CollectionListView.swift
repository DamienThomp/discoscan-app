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

    private var isFolder0: Bool { folderId == 0 }

    private var releasesState: ResourceState<[CollectionReleaseItem]> {
        isFolder0 ? store.folder0Items : (store.releasesByFolderID[folderId] ?? .idle)
    }

    private var displayedItems: [CollectionReleaseItem] {
        guard isFolder0 else {
            return releasesState.value ?? []
        }
        return store.searchFolder0(query: searchText)
    }

    private var emptyState: AnimatedEmptyStateView.Configuration {
        .init(
            title: "Collection",
            systemImage: "square.stack",
            description: isFolder0 && !searchText.isEmpty
                ? "No matching releases in your collection."
                : "This folder is empty.",
            effect: .bounceDown
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if isFolder0 {
                CollectionSyncBanner(phase: store.folder0Sync)
            }

            ResourceContainerView(
                state: releasesState,
                retry: {
                    if isFolder0 {
                        await store.refreshCollectionIndex()
                    } else {
                        await store.refreshReleases(folderId: folderId)
                    }
                }
            ) { _ in
                PaginatedReleaseListView(
                    items: displayedItems,
                    emptyState: emptyState,
                    canLoadMore: isFolder0 ? false : store.canLoadMore(folderId: folderId),
                    loadMore: { await store.loadMoreReleases(folderId: folderId) },
                    delete: { item in
                        await store.deleteRelease(
                            from: item.folderId,
                            releaseId: item.releaseId,
                            instanceId: item.instanceId
                        )
                    }
                )
            }
        }
        .navigationTitle(folderName)
        .if(isFolder0) { view in
            view.searchable(text: $searchText, prompt: "Search your collection…")
        }
        .task {
            if isFolder0 {
                await store.ensureFolder0IndexReady()
            } else if releasesState == .idle {
                await store.loadReleases(folderId: folderId)
            }
        }
        .refreshable {
            if isFolder0 {
                await store.refreshCollectionIndex()
            } else {
                await store.refreshReleases(folderId: folderId)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    PreviewAppRouteStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesLoaded(folderId: 1)))
}

#Preview("Folder 0 Loaded") {
    PreviewAppRouteStack {
        CollectionListView(folderId: 0, folderName: "All")
    }
    .environment(\.collectionStore, previewCollectionStore(.folder0Loaded))
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
