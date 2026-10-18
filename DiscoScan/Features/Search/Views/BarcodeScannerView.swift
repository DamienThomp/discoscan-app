//
//  BarcodeScannerView.swift
//  DiscoScan
//

import SwiftUI
import UIKit
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
                        .accessibilityHint("Tap a highlighted barcode to search.")
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
                ToolbarItem(placement: .bottomBar) {
                    Text("Tap a highlighted barcode to search.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

/// Symbologies for record retail + common label formats. UPC-A is reported as EAN-13.
/// If plain EAN-13 still fails in the field, try `.barcode()` (empty symbologies) and trim using DEBUG symbology logs.
private let vinylRetailBarcodeSymbologies: [VNBarcodeSymbology] = [
    .ean8, .ean13, .upce,
    .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited,
    .code128, .code93, .code93i,
    .code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum,
    .itf14, .i2of5, .i2of5Checksum,
    .codabar, .msiPlessey,
]

private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let reduceMotion: Bool

    func makeUIViewController(context: Context) -> BarcodeScannerContainerViewController {
        let dataScanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: vinylRetailBarcodeSymbologies)],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        dataScanner.delegate = context.coordinator
        return BarcodeScannerContainerViewController(dataScanner: dataScanner)
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerContainerViewController, context: Context) {
        context.coordinator.onScan = onScan
        context.coordinator.reduceMotion = reduceMotion
    }

    static func dismantleUIViewController(
        _ uiViewController: BarcodeScannerContainerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.dataScanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, reduceMotion: reduceMotion)
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onScan: (String) -> Void
        var reduceMotion: Bool
        private var didScan = false

        init(onScan: @escaping (String) -> Void, reduceMotion: Bool) {
            self.onScan = onScan
            self.reduceMotion = reduceMotion
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            accept(item: item, from: dataScanner)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                accept(item: item, from: dataScanner)
                if didScan { return }
            }
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in updatedItems {
                accept(item: item, from: dataScanner)
                if didScan { return }
            }
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
        ) {
            #if DEBUG
            print("DataScanner became unavailable: \(error)")
            #endif
        }

        private func accept(item: RecognizedItem, from dataScanner: DataScannerViewController) {
            guard !didScan else { return }
            guard case .barcode(let barcode) = item else { return }

            let payload = Self.resolvePayload(from: barcode)
            guard !payload.isEmpty else { return }

            #if DEBUG
            print(
                "Barcode accepted symbology: \(barcode.observation.symbology.rawValue), payload length: \(payload.count)"
            )
            #endif

            didScan = true
            if !reduceMotion {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            onScan(payload)
            dataScanner.stopScanning()
        }

        private static func resolvePayload(from barcode: RecognizedItem.Barcode) -> String {
            if let primary = barcode.payloadStringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !primary.isEmpty {
                return primary
            }
            if let supplemental = barcode.observation.supplementalPayloadString?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !supplemental.isEmpty {
                return supplemental
            }
            return ""
        }
    }
}

private final class BarcodeScannerContainerViewController: UIViewController {
    let dataScanner: DataScannerViewController
    private var didAttemptStartScanning = false

    init(dataScanner: DataScannerViewController) {
        self.dataScanner = dataScanner
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(dataScanner)
        dataScanner.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dataScanner.view)
        NSLayoutConstraint.activate([
            dataScanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dataScanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dataScanner.view.topAnchor.constraint(equalTo: view.topAnchor),
            dataScanner.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        dataScanner.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAttemptStartScanning else { return }
        didAttemptStartScanning = true

        do {
            try dataScanner.startScanning()
        } catch {
            #if DEBUG
            print("DataScanner startScanning failed: \(error)")
            #endif
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataScanner.stopScanning()
    }
}
