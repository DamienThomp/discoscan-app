//
//  WantListView.swift
//  DiscoScan
//

import NetworkKit
import SwiftUI

struct WantListView: View {

    @Environment(AuthSession.self) private var authSession
    @Environment(\.cachedFetcher) private var cacheFetcher

    var body: some View {
        LoadingContainerView(loadingAction: fetchWantList) { list in
            if list.wants.isEmpty {
                ContentUnavailableView(
                    "Want List",
                    systemImage: "heart",
                    description: Text("Your want list is empty.")
                )
            } else {
                List(list.wants) { item in
                    Text(item.basicInformation.title)
                }
            }
        }
    }
}

extension WantListView {

    @Sendable
    private func fetchWantList() async throws -> WantListResponse {
        guard case .authenticated(let identity) = authSession.state else {
            throw AuthSessionError.notAuthenticated
        }
        let endpoint = WantListEndpoint(username: identity.username)
        return try await cacheFetcher.fetch(
            endpoint,
            key: "wants",
            scope: .wantlist,
            userScope: identity.username,
            forceRefresh: false
        )
    }
}

#Preview {
    NavigationStack {
        WantListView()
            .environment(previewAuthenticatedAuthSession())
            .environment(\.cachedFetcher, PreviewEmptyWantListCachedFetcher())
    }
}
