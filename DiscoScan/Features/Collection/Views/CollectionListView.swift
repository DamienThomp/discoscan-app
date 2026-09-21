//
//  CollectionListView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionListView: View {

    let folderId: Int
    let folderName: String

    @Environment(\.collectionStore) private var store

    private var releasesState: ResourceState<[CollectionReleaseItem]> {
        store.releasesByFolderID[folderId] ?? .idle
    }

    var body: some View {
        ResourceContainerView(
            state: releasesState,
            retry: { await store.loadReleases(folderId: folderId, forceRefresh: true) }
        ) { releases in
            PaginatedReleaseListView(
                items: releases,
                emptyState: .init(
                    title: "Collection",
                    systemImage: "square.stack",
                    description: "This folder is empty.",
                    effect: .bounceDown
                ),
                releaseID: { $0.releaseId },
                basicInformation: { $0.basicInformation },
                canLoadMore: store.canLoadMore(folderId: folderId),
                loadMore: { await store.loadMoreReleases(folderId: folderId) },
                delete: { item in
                    await store.deleteRelease(
                        from: folderId,
                        releaseId: item.releaseId,
                        instanceId: item.instanceId
                    )
                }
            )
        }
        .navigationTitle(folderName)
        .task {
            if releasesState == .idle {
                await store.loadReleases(folderId: folderId)
            }
        }
        .refreshable {
            await store.loadReleases(folderId: folderId, forceRefresh: true)
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
