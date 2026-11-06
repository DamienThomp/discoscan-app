//
//  SearchView.swift
//  DiscoScan
//

import SwiftUI

struct SearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.searchStore) private var searchStore

    @Binding var searchText: String

    @State private var isShowingBarcodeScanner = false
    @State private var isShowingImageIdentification = false

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

            if !searchStore.recentQueries.isEmpty {
                Section("Recent") {
                    ForEach(searchStore.recentQueries, id: \.self) { query in
                        Button(query) {
                            router.submitSearch(.text(query: query))
                        }
                    }
                    .onDelete(perform: deleteRecentSearches)

                    Button("Clear Recent Searches", role: .destructive) {
                        clearRecentSearches()
                    }
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Clear recent searches")
                }
            }
        }
        .navigationTitle("Search")
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
        let queriesToRemove = offsets.map { searchStore.recentQueries[$0] }
        searchStore.removeRecentQueries(queriesToRemove)
    }

    private func clearRecentSearches() {
        withAnimation {
            searchStore.clearRecentQueries()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
            .environment(AppRouter())
            .environment(\.searchStore, previewSearchStore(.loaded(context: .text(query: "Kind of Blue"))))
            .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
    }
}
#endif
