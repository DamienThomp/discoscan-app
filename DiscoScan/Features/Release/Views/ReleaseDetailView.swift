//
//  ReleaseDetailView.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailView: View {

    let releaseID: Int

    @Environment(\.releaseStore) private var releaseStore
    @Environment(\.wantListStore) private var wantListStore
    @Environment(\.collectionStore) private var collectionStore

    @State private var showFolderPicker = false

    private var detailState: ResourceState<ReleaseDetailResponse> {
        releaseStore.detail(for: releaseID)
    }

    private var navigationTitle: String {
        if case .loaded(let release) = detailState {
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
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                wantListButton
                addToCollectionButton
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerSheet(releaseId: releaseID).presentationDetents([.fraction(0.25), .large])
        }
        .task {
            if releaseStore.detail(for: releaseID) == .idle {
                await releaseStore.loadRelease(id: releaseID)
            }
            await wantListStore.ensureWantsLoaded()
        }
    }

    private var wantListButton: some View {
        Button {
            Task {
                if wantListStore.isInWantList(releaseId: releaseID) {
                    await wantListStore.deleteRelease(releaseId: releaseID)
                } else {
                    await wantListStore.addRelease(releaseId: releaseID)
                }
            }
        } label: {
            Image(systemName: wantListStore.isInWantList(releaseId: releaseID) ? "heart.fill" : "heart")
        }
        .disabled(wantListStore.isMutating)
        .accessibilityLabel(wantListAccessibilityLabel)
        .accessibilityHint("Double tap to toggle want list status")
        .accessibilityAddTraits(
            wantListStore.isInWantList(releaseId: releaseID) ? .isSelected : []
        )
    }

    private var wantListAccessibilityLabel: String {
        if wantListStore.isMutating {
            return "Updating want list"
        }
        return wantListStore.isInWantList(releaseId: releaseID)
            ? "Remove from Want List"
            : "Add to Want List"
    }

    private var addToCollectionButton: some View {
        Button {
            showFolderPicker = true
        } label: {
            Image(systemName: "plus.square.on.square")
        }
        .disabled(collectionStore.isMutating)
        .accessibilityLabel("Add to Collection")
        .accessibilityHint("Opens folder picker")
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
}

#Preview("Loading") {
    PreviewAppRouteStack {
        ReleaseDetailView(releaseID: 249_504)
    }
    .environment(\.releaseStore, previewReleaseStore(.loading(id: 249_504)))
    .environment(\.wantListStore, previewWantListStore(.wantsEmpty))
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
}

#Preview("Failed") {
    PreviewAppRouteStack {
        ReleaseDetailView(releaseID: 249_504)
    }
    .environment(\.releaseStore, previewReleaseStore(.failed(id: 249_504, message: "Could not load release.")))
    .environment(\.wantListStore, previewWantListStore(.wantsEmpty))
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
}
#endif
