//
//  CollectionListView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionListView: View {

    let folderId: Int
    let folderName: String

    @Environment(CollectionStore.self) private var store

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

#Preview {
    NavigationStack {
        CollectionListView(folderId: 1, folderName: "Jazz")
    }
}
