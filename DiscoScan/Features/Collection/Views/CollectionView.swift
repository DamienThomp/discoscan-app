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
    @State private var showSheet: Bool = false

    var body: some View {
        VStack {

            Picker("Select Collection", selection: $selectedType) {
                ForEach(CollectionTypes.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedType {
                case .collectionList:
                    CollectionFolderView()
                case .wantlist:
                    WantListView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            Text("Use this sheet to create new collection folders")
        }
        .navigationTitle("Library")
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack {
        CollectionView().preferredColorScheme(.dark)
    }
    .environment(\.collectionStore, previewCollectionStore(.foldersLoaded))
    .environment(previewAuthenticatedAuthSession())
    .environment(\.cachedFetcher, PreviewEmptyWantListCachedFetcher())
}
#endif
