//
//  SearchResultsContent.swift
//  DiscoScan
//

import SwiftUI

struct SearchResultsContent: View {
    @Environment(AppRouter.self) private var router

    let context: SearchContext
    let response: SearchResponse

    @State private var didAutoNavigateToSingleBarcodeMatch = false

    var body: some View {
        Group {
            if response.results.isEmpty {
                SearchResultsEmptyView(context: context)
            } else {
                List(response.results) { result in
                    NavigationLink(value: AppRoute.releaseDetail(id: result.id)) {
                        SearchResultRow(result: result)
                    }
                }
            }
        }
        .onAppear {
            navigateToSingleBarcodeMatchIfNeeded()
        }
    }

    private func navigateToSingleBarcodeMatchIfNeeded() {
        guard !didAutoNavigateToSingleBarcodeMatch,
              context.isBarcode,
              response.results.count == 1,
              let result = response.results.first,
              result.type == "release" else {
            return
        }
        didAutoNavigateToSingleBarcodeMatch = true
        router.navigate(to: .releaseDetail(id: result.id), tab: .search)
    }
}
