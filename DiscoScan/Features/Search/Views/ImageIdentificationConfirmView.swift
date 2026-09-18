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

    var body: some View {
        Form {
            if let imageData {
                Section {
                    IdentificationImagePreview(imageData: imageData, maxHeight: 180)
                        .frame(maxWidth: .infinity)
                }
            }

            if identification.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Couldn't identify this sleeve",
                        systemImage: "questionmark.circle",
                        description: Text("Try the barcode on the back cover or search manually.")
                    )
                }
            } else {
                Section("Best guess") {
                    TextField("Artist", text: $identification.artist)
                    TextField("Album title", text: $identification.title)
                    TextField("Catalog number", text: $identification.catalogNumber)
                }
            }

            Section {
                if !identification.isEmpty {
                    Button("Search Discogs") {
                        onSearch(identification.searchQuery)
                    }
                    .disabled(identification.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Button("Edit in search field") {
                    onSearchManually()
                }

                Button("Scan barcode instead") {
                    onScanBarcode()
                }
            }
        }
    }
}
