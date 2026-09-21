//
//  AppRouteDestination.swift
//  DiscoScan
//

import SwiftUI

struct AppRouteDestination: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .searchResults(let context):
            SearchResultsView(context: context)
        case .releaseDetail(let id):
            ReleaseDetailView(releaseID: id)
        case .collectionFolder(let id, let name):
            CollectionListView(folderId: id, folderName: name)
        }
    }
}
