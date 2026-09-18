//
//  BarcodeScannerView.swift
//  DiscoScan
//

import SwiftUI
import Vision
import VisionKit

struct BarcodeScannerView: View {
    let onScan: (String) -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    BarcodeScannerRepresentable(onScan: onScan, reduceMotion: reduceMotion)
                } else {
                    ContentUnavailableView(
                        "Scanner Unavailable",
                        systemImage: "barcode.viewfinder",
                        description: Text("Barcode scanning is not available on this device.")
                    )
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let reduceMotion: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .upce])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.onScan = onScan
        context.coordinator.reduceMotion = reduceMotion

        guard !uiViewController.isScanning else { return }
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, reduceMotion: reduceMotion)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onScan: (String) -> Void
        var reduceMotion: Bool
        private var didScan = false

        init(onScan: @escaping (String) -> Void, reduceMotion: Bool) {
            self.onScan = onScan
            self.reduceMotion = reduceMotion
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !didScan else { return }

            for item in addedItems {
                guard case .barcode(let barcode) = item,
                      let payload = barcode.payloadStringValue else {
                    continue
                }
                didScan = true
                if !reduceMotion {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                onScan(payload)
                dataScanner.stopScanning()
                return
            }
        }
    }
}
