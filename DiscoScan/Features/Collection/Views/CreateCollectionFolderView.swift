//
//  CreateCollectionFolderView.swift
//  DiscoScan
//

import SwiftUI

struct CreateCollectionFolderView: View {

    @Environment(\.collectionStore) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        Form {
            TextField("Name", text: $name)
        }
        .navigationTitle("Create Folder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { await submitForm() }
                }
                .disabled(!canSubmit || isSubmitting)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Couldn't Create Folder", isPresented: isShowingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }
}

extension CreateCollectionFolderView {

    private var canSubmit: Bool {
        if case .success = FolderName.validated(from: name) { return true }
        return false
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func submitForm() async {
        guard case .success(let folderName) = FolderName.validated(from: name) else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await store.createFolder(name: folderName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CreateCollectionFolderView()
            .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
    }
}
#endif
