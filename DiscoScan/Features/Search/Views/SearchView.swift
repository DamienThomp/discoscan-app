//
//  SearchView.swift
//  DiscoScan
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        ContentUnavailableView(
            "Search",
            systemImage: "magnifyingglass",
            description: Text("Search by text, scan a barcode, or scan text from a record sleeve.")
        )
        .navigationTitle("Search")
    }
}
