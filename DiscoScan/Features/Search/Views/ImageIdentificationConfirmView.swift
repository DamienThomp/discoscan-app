//
//  ImageIdentificationConfirmView.swift
//  DiscoScan
//

import SwiftUI

struct ImageIdentificationConfirmView: View {
    @Binding var identification: SleeveIdentificationDraft
    let imageData: Data?
    let onSearch: (String) -> Void
    let onScanBarcode: () -> Void
    let onSearchManually: () -> Void
    let onTryAnotherPhoto: () -> Void

    var body: some View {
        Form {
            if let imageData {
                Section {
                    IdentificationImagePreview(imageData: imageData)
                        .scaledToFill()
                        .frame(maxHeight: 240)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.standard))
                        .transition(.opacity)
                }
            }
            if identification.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Couldn't identify this sleeve",
                        systemImage: "questionmark.circle",
                        description: Text("Try the barcode on the back cover or search manually.")
                    )
                }.transition(.opacity)

                Section {
                    Button("Try Another Photo", action: onTryAnotherPhoto)

                    Button("Scan barcode instead") {
                        onScanBarcode()
                    }

                    Button("Search manually") {
                        onSearchManually()
                    }
                }.transition(.opacity)
            } else {
                Section("Best guess") {
                    TextField("Artist", text: $identification.artist)
                    TextField("Album title", text: $identification.title)
                    TextField("Catalog number", text: $identification.catalogNumber)
                }.transition(.opacity)

                Section {
                    Button("Search Discogs") {
                        onSearch(identification.searchQuery)
                    }
                    .disabled(identification.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Edit in search field") {
                        onSearchManually()
                    }

                    Button("Scan barcode instead") {
                        onScanBarcode()
                    }
                }.transition(.opacity)
            }
        }
    }
}
