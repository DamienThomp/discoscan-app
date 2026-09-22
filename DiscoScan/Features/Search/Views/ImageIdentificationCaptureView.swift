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

struct ImagePickerCameraView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (Data) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.85) {
                onCapture(data)
            } else {
                onCancel()
            }
        }
    }
}
