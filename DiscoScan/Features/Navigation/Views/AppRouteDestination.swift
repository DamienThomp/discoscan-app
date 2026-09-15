//
//  AppRouteDestination.swift
//  DiscoScan
//

import SwiftUI

struct AppRouteDestination: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .searchResults(let query):
            SearchResultsView(query: query)
        case .releaseDetail(let id):
            ReleaseDetailView(releaseID: id)
        case .userProfile(let username):
            UserProfileView(username: username)
        case .collectionFolder(let id, let name):
            CollectionListView(folderId: id, folderName: name)
        }
    }
}
