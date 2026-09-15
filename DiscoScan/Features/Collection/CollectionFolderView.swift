//
//  CollectionFolderView.swift
//  DiscoScan
//

import SwiftUI

struct CollectionFolderView: View {

    @Environment(AuthSession.self) private var authSession
    @Environment(\.cachedFetcher) private var cacheFetcher

    var body: some View {
        LoadingContainerView(loadingAction: fetchCollectionFolders) {
         collection in
            List {
                ForEach(collection.folders, id: \.id) { folder in
                    Label {
                        Text(folder.name)
                    } icon: {
                        Image(systemName: "folder")
                    }
                }
            }
        }
    }
}

extension CollectionFolderView {

    @Sendable
    private func fetchCollectionFolders() async throws -> CollectionFoldersResponse {
        guard case .authenticated(let identity) = authSession.state else {
            throw AuthSessionError.notAuthenticated
        }
        let endpoint = CollectionFoldersEndpoint(userName: identity.username)
        return try await cacheFetcher.fetch(
            endpoint,
            key: "collectionFolders",
            scope: .collection,
            userScope: identity.username,
            forceRefresh: false
        )
    }
}

//#Preview {
//    CollectionFolderView()
//}
