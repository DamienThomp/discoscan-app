//
//  CollectionView.swift
//  DiscoScan
//

import SwiftUI

enum CollectionTypes: String, CaseIterable, Identifiable {
    case collectionList = "Collection"
    case wantlist = "Wantlist"

    var id: String { self.rawValue }
}

struct CollectionView: View {

    @State private var selectedType: CollectionTypes = .collectionList

    var body: some View {
        Group {
            switch selectedType {
            case .collectionList:
                CollectionListView()
            case .wantlist:
                WantListView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Select Collection", selection: $selectedType) {
                    ForEach(CollectionTypes.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

#Preview {
    NavigationView {
        CollectionView()
    }
}
