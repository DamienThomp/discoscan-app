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

    let imageData: Data?
    let isAnalyzing: Bool
    let errorMessage: String?

    var body: some View {
        VStack(spacing: AppSpacing.screen) {
            if let imageData {
                IdentificationImagePreview(imageData: imageData)
            }

            if isAnalyzing {
                ProgressView("Analyzing sleeve…")
            } else {
                VStack(spacing: AppSpacing.section) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

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

            if let errorMessage {
                SecondaryFootnoteText(text: errorMessage)
            }

            SecondaryFootnoteText(
                text: "Include the spine or back cover when the front has no text."
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Idle") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        imageData: nil,
        isAnalyzing: false,
        errorMessage: nil
    )
}

#Preview("Analyzing") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        imageData: nil,
        isAnalyzing: true,
        errorMessage: nil
    )
}

#Preview("Failed") {
    ImageIdentificationCaptureView(
        selectedPhotoItem: .constant(nil),
        isShowingCamera: .constant(false),
        imageData: nil,
        isAnalyzing: false,
        errorMessage: "Could not load the selected photo."
    )
}
#endif


