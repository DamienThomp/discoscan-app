//
//  ImageIdentificationSheet.swift
//  DiscoScan
//

import PhotosUI
import SwiftUI

struct ImageIdentificationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sleeveIdentifier) private var sleeveIdentifier

    @Binding var searchText: String

    let onSearch: (String) -> Void

    @State private var step: Step = .capture
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var identification = SleeveIdentificationDraft()
    @State private var errorMessage: String?
    @State private var isAnalyzing = false
    @State private var isShowingCamera = false

    enum Step {
        case capture
        case confirm
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .capture:
                    ImageIdentificationCaptureView(
                        selectedPhotoItem: $selectedPhotoItem,
                        isShowingCamera: $isShowingCamera,
                        imageData: imageData,
                        isAnalyzing: isAnalyzing,
                        errorMessage: errorMessage
                    ).transition(.opacity)
                case .confirm:
                    ImageIdentificationConfirmView(
                        identification: $identification,
                        imageData: imageData,
                        onSearch: onSearch,
                        onScanBarcode: { dismiss() },
                        onSearchManually: {
                            searchText = identification.searchQuery
                            dismiss()
                        }
                    ).transition(.opacity)
                }
            }
            .navigationTitle("Identify Sleeve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task { await loadPhoto(from: newItem) }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                ImagePickerCameraView { data in
                    isShowingCamera = false
                    imageData = data
                    Task { await analyzeImage() }
                } onCancel: {
                    isShowingCamera = false
                }.ignoresSafeArea()
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Could not load the selected photo."
                return
            }
            withAnimation {
                imageData = data
            }
            await analyzeImage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyzeImage() async {
        guard let imageData else { return }

        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            let result = try await sleeveIdentifier.identify(jpegData: imageData)
            identification = SleeveIdentificationDraft(from: result)
            withAnimation {
                step = .confirm
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    ImageIdentificationSheet(searchText: .constant("")) { _ in }
        .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
}
#endif
