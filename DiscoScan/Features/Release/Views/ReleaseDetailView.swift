//
//  ReleaseDetailView.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailView: View {

    let releaseID: Int

    @Environment(\.releaseStore) private var releaseStore
    @Environment(\.wantListStore) private var wantListStore

    @State private var showFolderPicker = false

    private var detailState: ResourceState<ReleaseDetailResponse> {
        releaseStore.detail(for: releaseID)
    }

    private var navigationTitle: String {
        if let release = detailState.value {
            return release.title
        }
        return "Release"
    }

    var body: some View {
        ResourceContainerView(
            state: detailState,
            retry: { await releaseStore.loadRelease(id: releaseID, forceRefresh: true) }
        ) { release in
            ReleaseDetailContent(release: release)
                .transition(.opacity)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                WantListToolbarButton(releaseId: releaseID)
                AddToCollectionToolbarButton(
                    isPresentingFolderPicker: $showFolderPicker,
                    isEnabled: detailState.value != nil
                )
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerSheet(
                releaseId: releaseID,
                snapshot: detailState.value?.asCollectionSnapshot()
            )
            .presentationDetents([.large])
        }
        .task {
            if releaseStore.detail(for: releaseID) == .idle {
                await releaseStore.loadRelease(id: releaseID)
            }
            await wantListStore.ensureWantsLoaded()
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    PreviewAppRouteStack {
        ReleaseDetailView(releaseID: 249_504)
    }
    .environment(\.releaseStore, previewReleaseStore(.loaded(id: 249_504)))
    .environment(\.wantListStore, previewWantListStore(.wantsLoaded))
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
    .environment(\.appleMusicCatalog, PreviewAppleMusicCatalog())
}

#Preview("Loading") {
    PreviewAppRouteStack {
        ReleaseDetailView(releaseID: 249_504)
    }
    .environment(\.releaseStore, previewReleaseStore(.loading(id: 249_504)))
    .environment(\.wantListStore, previewWantListStore(.wantsEmpty))
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
    .environment(\.appleMusicCatalog, PreviewAppleMusicCatalog())
}

#Preview("Failed") {
    PreviewAppRouteStack {
        ReleaseDetailView(releaseID: 249_504)
    }
    .environment(\.releaseStore, previewReleaseStore(.failed(id: 249_504, message: "Could not load release.")))
    .environment(\.wantListStore, previewWantListStore(.wantsEmpty))
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
    .environment(\.appleMusicCatalog, PreviewAppleMusicCatalog())
}
#endif
