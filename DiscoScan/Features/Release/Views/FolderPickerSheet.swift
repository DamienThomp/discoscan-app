//
//  FolderPickerSheet.swift
//  DiscoScan
//

import SwiftUI

struct FolderPickerSheet: View {
    let releaseId: Int

    @Environment(\.collectionStore) private var collectionStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFolderId = 1
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ResourceContainerView(
                state: collectionStore.folders,
                retry: { await collectionStore.loadFolders(forceRefresh: true) }
            ) { folders in
                List {
                    Picker("Folder", selection: $selectedFolderId) {
                        ForEach(folders.filter { $0.id >= 1 }) { folder in
                            Text(folder.name)
                                .tag(folder.id)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await collectionStore.addRelease(
                                releaseId: releaseId,
                                folderId: selectedFolderId
                            )
                            if collectionStore.lastMutationError == nil {
                                dismiss()
                            } else {
                                showErrorAlert = true
                            }
                        }
                    }
                    .disabled(collectionStore.isMutating)
                    .accessibilityLabel(
                        collectionStore.isMutating ? "Adding release" : "Add"
                    )
                }
            }
            .task {
                if collectionStore.folders == .idle {
                    await collectionStore.loadFolders()
                }
            }
            .alert("Could Not Add Release", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = collectionStore.lastMutationError {
                    Text(message)
                }
            }
        }
    }
}
