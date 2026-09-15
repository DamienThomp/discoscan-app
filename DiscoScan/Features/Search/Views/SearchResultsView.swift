//
//  SearchResultsView.swift
//  DiscoScan
//

import SwiftUI

struct SearchResultsView: View {
    let query: String

    var body: some View {
        ContentUnavailableView(
            "Results for \"\(query)\"",
            systemImage: "magnifyingglass",
            description: Text("Search results will appear here.")
        )
        .navigationTitle("Results")
    }
}
