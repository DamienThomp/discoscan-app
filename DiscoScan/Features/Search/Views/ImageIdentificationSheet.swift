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
    @State private var draft = SleeveIdentificationDraft()
    @State private var imageData: Data?
    @State private var isShowingCamera = false
    @State private var analysisAttempt = 0

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .capturing, .analyzing, .captureFailed:
                    ImageIdentificationCaptureView(
                        selectedPhotoItem: $selectedPhotoItem,
                        isShowingCamera: $isShowingCamera,
                        phase: phase,
                        imageData: imageData,
                        onRetry: retryAnalysis,
                        onSearchManually: {
                            searchText = draft.searchQuery
                            dismiss()
                        },
                        onScanBarcode: { dismiss() }
                    ).transition(.opacity)
                case .confirming:
                    ImageIdentificationConfirmView(
                        identification: $draft,
                        imageData: imageData,
                        onSearch: onSearch,
                        onScanBarcode: { dismiss() },
                        onSearchManually: {
                            searchText = draft.searchQuery
                            dismiss()
                        },
                        onTryAnotherPhoto: tryAnotherPhoto
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
            .task(id: selectedPhotoItem) {
                await loadPhoto(from: selectedPhotoItem)
            }
            .task(id: analysisAttempt) {
                await runAnalysis()
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                ImagePickerCameraView { data in
                    isShowingCamera = false
                    beginAnalysis(with: data)
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

    private func beginAnalysis(with data: Data) {
        withAnimation {
            imageData = data
            phase = .analyzing
            analysisAttempt += 1
        }
    }

    private func retryAnalysis() {
        withAnimation {
            phase = .analyzing
            analysisAttempt += 1
        }
    }

    private func completeAnalysis(with result: SleeveIdentification) {
        withAnimation {
            draft = SleeveIdentificationDraft(from: result)
            phase = .confirming
        }
    }

    private func failCapture(_ failure: ImageIdentificationFailure) {
        withAnimation {
            phase = .captureFailed(failure)
        }
    }

    private func tryAnotherPhoto() {
        withAnimation {
            imageData = nil
            draft = SleeveIdentificationDraft()
            phase = .capturing
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        defer { selectedPhotoItem = nil }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                failCapture(.photoUnavailable)
                return
            }
            beginAnalysis(with: data)
        } catch {
            failCapture(.photoUnavailable)
        }
    }

    private func runAnalysis() async {
        guard analysisAttempt > 0, let imageData else { return }

        do {
            let result = try await sleeveIdentifier.identify(jpegData: imageData)
            guard !Task.isCancelled else { return }
            completeAnalysis(with: result)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            failCapture(ImageIdentificationFailure(error: error))
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
            onSearchManually: {},
            onTryAnotherPhoto: {}
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
            onSearchManually: {},
            onTryAnotherPhoto: {}
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
