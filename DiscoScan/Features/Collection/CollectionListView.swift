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
            if releases.isEmpty {
                ContentUnavailableView(
                    "Collection",
                    systemImage: "square.stack",
                    description: Text("This folder is empty.")
                )
            } else {
                List(releases) { item in
                    Text(item.basicInformation.title)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await store.deleteRelease(
                                        from: folderId,
                                        releaseId: item.releaseId,
                                        instanceId: item.instanceId
                                    )
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
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
    NavigationStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesLoaded(folderId: 1)))
}

#Preview("Empty") {
    NavigationStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesEmpty(folderId: 1)))
}

#Preview("Failed") {
    NavigationStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesFailed(folderId: 1, message: "Could not load releases.")))
}

#Preview("Loading") {
    NavigationStack {
        CollectionListView(folderId: 1, folderName: "Uncategorized")
    }
    .environment(\.collectionStore, previewCollectionStore(.releasesLoading(folderId: 1)))
}
#endif
