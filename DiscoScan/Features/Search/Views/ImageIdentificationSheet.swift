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

    @State private var phase: ImageIdentificationPhase = .capturing
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isShowingCamera = false

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .capturing, .analyzing, .captureFailed:
                    ImageIdentificationCaptureView(
                        selectedPhotoItem: $selectedPhotoItem,
                        isShowingCamera: $isShowingCamera,
                        imageData: imageData,
                        isAnalyzing: phase == .analyzing,
                        errorMessage: phase.captureErrorMessage
                    ).transition(.opacity)
                case .confirming:
                    ImageIdentificationConfirmView(
                        identification: identificationBinding,
                        imageData: imageData,
                        onSearch: onSearch,
                        onScanBarcode: { dismiss() },
                        onSearchManually: {
                            searchText = identificationBinding.wrappedValue.searchQuery
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
                    beginAnalysis(with: data)
                    Task { await runAnalysis() }
                } onCancel: {
                    isShowingCamera = false
                }.ignoresSafeArea()
            }
            .sensoryFeedback(trigger: feedbackPhase) { _, newPhase in
                switch newPhase {
                case .confirmed:
                    .success
                case .failed:
                    .error
                default:
                    nil
                }
            }
        }
    }

    private var feedbackPhase: ImageIdentificationFeedbackPhase {
        phase.feedbackPhase
    }

    private var identificationBinding: Binding<SleeveIdentificationDraft> {
        Binding(
            get: {
                if case .confirming(let draft) = phase {
                    draft
                } else {
                    SleeveIdentificationDraft()
                }
            },
            set: { phase = .confirming($0) }
        )
    }

    private func beginAnalysis(with data: Data) {
        withAnimation {
            imageData = data
            phase = .analyzing
        }
    }

    private func completeAnalysis(with result: SleeveIdentification) {
        withAnimation {
            phase = .confirming(SleeveIdentificationDraft(from: result))
        }
    }

    private func failCapture(_ message: String) {
        withAnimation {
            phase = .captureFailed(message)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                failCapture("Could not load the selected photo.")
                return
            }
            beginAnalysis(with: data)
            await runAnalysis()
        } catch {
            failCapture(error.localizedDescription)
        }
    }

    private func runAnalysis() async {
        guard let imageData else { return }

        do {
            let result = try await sleeveIdentifier.identify(jpegData: imageData)
            completeAnalysis(with: result)
        } catch {
            failCapture(error.localizedDescription)
        }
    }
}

#if DEBUG
#Preview("Capturing") {
    ImageIdentificationSheet(searchText: .constant("")) { _ in }
        .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
}

#Preview("Confirming") {
    NavigationStack {
        ImageIdentificationConfirmView(
            identification: .constant(previewSleeveIdentificationDraft()),
            imageData: nil,
            onSearch: { _ in },
            onScanBarcode: {},
            onSearchManually: {}
        )
        .navigationTitle("Identify Sleeve")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Confirming Empty") {
    NavigationStack {
        ImageIdentificationConfirmView(
            identification: .constant(SleeveIdentificationDraft()),
            imageData: nil,
            onSearch: { _ in },
            onScanBarcode: {},
            onSearchManually: {}
        )
        .navigationTitle("Identify Sleeve")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func previewSleeveIdentificationDraft() -> SleeveIdentificationDraft {
    var draft = SleeveIdentificationDraft()
    draft.artist = "Nine Inch Nails"
    draft.title = "Year Zero"
    draft.catalogNumber = "17064-2"
    return draft
}
#endif
