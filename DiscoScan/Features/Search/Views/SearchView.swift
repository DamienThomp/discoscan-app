//
//  SearchView.swift
//  DiscoScan
//

import SwiftUI

struct SearchView: View {
    @Environment(AppRouter.self) private var router

    @Binding var searchText: String

    @State private var recentSearches: [String] = []
    @State private var isShowingBarcodeScanner = false
    @State private var isShowingImageIdentification = false

    private let recentSearchStore = RecentSearchStore()

    var body: some View {
        List {


            Section("Find a record") {
                Group {
                    Button {
                        isShowingBarcodeScanner = true
                    } label: {
                        Label("Scan barcode", systemImage: "barcode.viewfinder")
                    }
                    .accessibilityLabel("Scan barcode")

                    Button {
                        isShowingImageIdentification = true
                    } label: {
                        Label("Identify from photo", systemImage: "camera.viewfinder")
                    }
                    .accessibilityLabel("Identify from photo")
                }.font(.title3)
            }

            Section {
                SecondaryFootnoteText(
                    text: "Photo ID works best with readable text or recognizable artwork. For plain covers, scan the barcode."
                )
            }

            if !recentSearches.isEmpty {
                Section("Recent") {
                    ForEach(recentSearches, id: \.self) { query in
                        Button(query) {
                            router.submitSearch(.text(query: query))
                        }
                    }
                    .onDelete(perform: deleteRecentSearches)
                }
            }
        }
        .navigationTitle("Search")
        .onAppear {
            recentSearches = recentSearchStore.load()
        }
        .fullScreenCover(isPresented: $isShowingBarcodeScanner) {
            BarcodeScannerView { code in
                isShowingBarcodeScanner = false
                router.submitSearch(.barcode(code: code))
            } onCancel: {
                isShowingBarcodeScanner = false
            }
        }
        .sheet(isPresented: $isShowingImageIdentification) {
            ImageIdentificationSheet(searchText: $searchText) { query in
                isShowingImageIdentification = false
                router.submitSearch(.imageSuggested(query: query))
            }
        }
    }

    private func deleteRecentSearches(at offsets: IndexSet) {
        for index in offsets {
            recentSearchStore.remove(recentSearches[index])
        }
        recentSearches = recentSearchStore.load()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
            .environment(AppRouter())
            .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
    }
}
#endif
