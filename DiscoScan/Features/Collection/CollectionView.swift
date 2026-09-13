//
//  CollectionView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionView: View {
    var body: some View {
        ContentUnavailableView(
            "Collection",
            systemImage: "square.stack",
            description: Text("Your Discogs collection will appear here.")
        )
        .navigationTitle("Collection")
    }
}
