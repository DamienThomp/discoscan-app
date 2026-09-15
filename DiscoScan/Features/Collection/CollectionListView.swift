//
//  CollectionListView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionListView: View {
    var body: some View {
        ContentUnavailableView(
            "Collection",
            systemImage: "square.stack",
            description: Text("Your Collection is empty. Add items to your collection to view them here.")
        )
    }
}

#Preview {
    CollectionListView()
}
