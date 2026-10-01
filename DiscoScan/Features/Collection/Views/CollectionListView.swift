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

    private var isFolderZero: Bool { folderId == .zero }

    private var releasesState: ResourceState<[CollectionReleaseItem]> {
        isFolderZero ? store.folderZeroItems : (store.releasesByFolderID[folderId] ?? .idle)
    }

    private var displayedItems: [CollectionReleaseItem] {
        guard isFolderZero else {
            return releasesState.value ?? []
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
                CollectionSyncBanner(phase: store.folderZeroSync) {
                    await store.syncFolderZeroIndex(forceRefresh: true)
                }
            }

            ResourceContainerView(
                state: releasesState,
                retry: {
                    if isFolderZero {
                        await store.syncFolderZeroIndex(forceRefresh: true)
                    } else {
                        await store.refreshReleases(folderId: folderId)
                    }
                }
            ) { _ in
                PaginatedReleaseListView(
                    items: displayedItems,
                    emptyState: emptyState,
                    canLoadMore: isFolderZero ? false : store.canLoadMore(folderId: folderId),
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
        .if(isFolderZero) { view in
            view.searchable(text: $searchText, prompt: "Search your collection…")
        }
        .task {
            if isFolderZero {
                await store.ensureFolderZeroIndexReady()
            } else if releasesState == .idle {
                await store.loadReleases(folderId: folderId)
            }
        }
        .refreshable {
            if isFolderZero {
                await store.syncFolderZeroIndex(forceRefresh: true)
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
