//
//  AddToCollectionToolbarButton.swift
//  DiscoScan
//

import SwiftUI

struct AddToCollectionToolbarButton: View {

    @Binding var isPresentingFolderPicker: Bool
    let isEnabled: Bool

    @Environment(\.collectionStore) private var collectionStore

    var body: some View {
        Button {
            isPresentingFolderPicker = true
        } label: {
            Image(systemName: "plus.square.on.square")
        }
        .disabled(collectionStore.isMutating || !isEnabled)
        .accessibilityLabel(collectionStore.isMutating ? "Adding release" : "Add to Collection")
        .accessibilityHint(collectionStore.isMutating || !isEnabled ? "" : "Opens folder picker")
    }
}

#if DEBUG
#Preview("Enabled") {
    @Previewable @State var isPresentingFolderPicker = false

    NavigationStack {
        Text("Release Detail")
            .toolbar {
                AddToCollectionToolbarButton(
                    isPresentingFolderPicker: $isPresentingFolderPicker,
                    isEnabled: true
                )
            }
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
}

#Preview("Disabled") {
    @Previewable @State var isPresentingFolderPicker = false

    NavigationStack {
        Text("Release Detail")
            .toolbar {
                AddToCollectionToolbarButton(
                    isPresentingFolderPicker: $isPresentingFolderPicker,
                    isEnabled: false
                )
            }
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
}
#endif
