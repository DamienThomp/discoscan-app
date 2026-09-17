//
//  CollectionFolderView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionFolderView: View {

    @Environment(\.collectionStore) private var store

    var body: some View {
        ResourceContainerView(
            state: store.folders,
            retry: { await store.loadFolders(forceRefresh: true) }
        ) { folders in
            List(folders) { folder in
                NavigationLink(value: AppRoute.collectionFolder(id: folder.id, name: folder.name)) {
                    Label {
                        Text(folder.name)
                    } icon: {
                        Image(systemName: "folder")
                    }
                    .badge(folder.count)
                }
            }.listStyle(.plain)
        }
        .task {
            if store.folders == .idle {
                await store.loadFolders()
            }
        }
        .refreshable {
            await store.loadFolders(forceRefresh: true)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    PreviewAppRouteStack {
        CollectionFolderView()
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
}

#Preview("Empty") {
    PreviewAppRouteStack {
        CollectionFolderView()
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersEmpty))
}

#Preview("Failed") {
    PreviewAppRouteStack {
        CollectionFolderView()
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersFailed("Could not load folders.")))
}

#Preview("Loading") {
    PreviewAppRouteStack {
        CollectionFolderView()
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersLoading))
}
#endif
