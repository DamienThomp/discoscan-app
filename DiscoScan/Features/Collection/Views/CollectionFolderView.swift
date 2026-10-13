//
//  CollectionFolderView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionFolderView: View {

    @Environment(\.collectionStore) private var store
    @State private var deleteErrorMessage: String?

    var body: some View {
        ResourceContainerView(
            state: store.folders,
            retry: { await store.loadFolders(forceRefresh: true) }
        ) { folders in
            List {
                ForEach(folders) { folder in
                    NavigationLink(
                        value: AppRoute.collectionFolder(
                            id: folder.id,
                            name: folder.name
                        )
                    ) {
                        Label {
                            Text(folder.name).font(.title2)
                        } icon: {
                            Image(
                                systemName: "folder"
                            )
                            .font(
                                .system(
                                    size: AppIconSize.listAction
                                )
                            )
                        }
                        .badge(folder.count)
                    }
                    .swipeActions {
                        if !folder.isSystemFolder {
                            Button(role: .destructive) {
                                Task {
                                    await performDelete(for: folder)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    .accessibilityLabel("\(folder.name), \(folder.count) items")
                }
            }
            .listStyle(.plain)
        }
        .task {
            if store.folders == .idle {
                await store.loadFolders()
            }
        }
        .refreshable {
            await store.loadFolders(forceRefresh: true)
        }
        .mutationErrorAlert(
            title: "Could Not Remove Folder",
            message: $deleteErrorMessage
        )
    }

    private func performDelete(for folder: CollectionFolderResponse) async {
        await store.deleteFolder(id: folder.id)
        if let message = store.lastMutationError {
            deleteErrorMessage = message
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
