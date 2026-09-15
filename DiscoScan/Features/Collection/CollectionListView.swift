//
//  CollectionListView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionListView: View {

    let folder: CollectionFolderResponse

    var body: some View {
        ContentUnavailableView(
            "Collection",
            systemImage: "square.stack",
            description: Text("Your Collection is empty. Add items to your collection to view them here.")
        )
    }
}

#Preview {
    NavigationStack {
        CollectionListView(
            folder: CollectionFolderResponse(
                id: 1,
                count: 1,
                name: "Jazz",
                resourceUrl: "https://www.discogs.com/collection/folder/1"
            )
        )
    }
}
