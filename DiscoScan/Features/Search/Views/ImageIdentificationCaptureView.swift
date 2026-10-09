//
//  ImageIdentificationCaptureView.swift
//  DiscoScan
//

import PhotosUI
import SwiftUI
import UIKit

struct ImageIdentificationCaptureView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var isShowingCamera: Bool

    let phase: ImageIdentificationPhase
    let imageData: Data?
    let onRetry: () -> Void
    let onSearchManually: () -> Void
    let onScanBarcode: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.screen) {
            switch phase {
            case .capturing:
                idleContent
            case .analyzing:
                analyzingContent
            case .captureFailed(let failure):
                failedContent(failure: failure)
            case .confirming:
                EmptyView()
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
        .background {
            if phase == .analyzing, let imageData {
                Color.clear
                    .overlay {
                        IdentificationImagePreview(imageData: imageData)
                            .scaledToFill()
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
            if phase == .analyzing {
                LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                    .ignoresSafeArea()
            }
        }
    }

    private var idleContent: some View {
        Group {
            if let imageData {
                IdentificationImagePreview(imageData: imageData)
            }

            imagePickerControls(libraryLabel: "Choose from Library", libraryIsPrimary: false)

            SecondaryFootnoteText(
                text: "Include the spine or back cover when the front has no text."
            )
        }
    }

    private var analyzingContent: some View {
        ProgressView("Analyzing sleeve…")
            .tint(.primary)
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: AppCornerRadius.standard))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failedContent(failure: ImageIdentificationFailure) -> some View {
        VStack {
            if let imageData {
                IdentificationImagePreview(imageData: imageData)
            }

            ContentUnavailableView {
                Text(failure.title)
            } description: {
                Text(failure.message)
            } actions: {
                failedActions(for: failure)
            }
            .accessibilityElement(children: .combine)
        }.frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func failedActions(for failure: ImageIdentificationFailure) -> some View {
        VStack(spacing: AppSpacing.section) {
            if failure.isRetryable {
                Button {
                    onRetry()
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if failure.isNotConfigured {
                Button {
                    onSearchManually()
                } label: {
                    Text("Search Manually")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    onScanBarcode()
                } label: {
                    Text("Scan Barcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                imagePickerControls(
                    libraryLabel: "Choose Another Photo",
                    libraryIsPrimary: failure == .photoUnavailable
                )

                Button {
                    onSearchManually()
                } label: {
                    Text("Search Manually")
                }
                .buttonStyle(.plain)
                .controlSize(.large)
            }
        }
    }

    @ViewBuilder
    private func imagePickerControls(libraryLabel: String, libraryIsPrimary: Bool) -> some View {
        VStack(spacing: AppSpacing.section) {
            if libraryIsPrimary {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(libraryLabel, systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle( .borderedProminent)
            } else {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(libraryLabel, systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                isShowingCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
    }
}

#if DEBUG
#Preview("Idle") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        phase: .capturing,
        imageData: nil,
        onRetry: {},
        onSearchManually: {},
        onScanBarcode: {}
    )
}

#Preview("Analyzing") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        phase: .analyzing,
        imageData: UIImage(named: "PreviewSleeve")?.jpegData(compressionQuality: 0.85),
        onRetry: {},
        onSearchManually: {},
        onScanBarcode: {}
    )
}

#Preview("Failed Offline") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        phase: .captureFailed(.identification(.offline)),
        imageData: UIImage(named: "PreviewSleeve")?.jpegData(compressionQuality: 0.85),
        onRetry: {},
        onSearchManually: {},
        onScanBarcode: {}
    )
}

#Preview("Failed Rate Limited") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        phase: .captureFailed(.identification(.rateLimited)),
        imageData: UIImage(named: "PreviewSleeve")?.jpegData(compressionQuality: 0.85),
        onRetry: {},
        onSearchManually: {},
        onScanBarcode: {}
    )
}

#Preview("Failed Photo Unavailable") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        phase: .captureFailed(.photoUnavailable),
        imageData: nil,
        onRetry: {},
        onSearchManually: {},
        onScanBarcode: {}
    )
}

#Preview("Failed Not Configured") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        phase: .captureFailed(.identification(.notConfigured)),
        imageData: UIImage(named: "PreviewSleeve")?.jpegData(compressionQuality: 0.85),
        onRetry: {},
        onSearchManually: {},
        onScanBarcode: {}
    )
}
#endif
