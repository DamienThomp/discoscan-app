//
//  RootView.swift
//  DiscoScan
//

import SwiftUI

struct RootView: View {
    @Environment(AuthSession.self) private var authSession

    var body: some View {
        Group {
            switch authSession.state {
            case .unauthenticated, .failed:
                LoginView()
            case .authenticating:
                ProgressView("Connecting to Discogs…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .authenticated:
                AuthenticatedRootView()
            }
        }
        .animation(.default, value: authSession.state)
    }
}

private struct AuthenticatedRootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .searchResults(let query):
                        SearchResultsView(query: query)
                    case .releaseDetail(let id):
                        ReleaseDetailView(releaseID: id)
                    case .profile(let username):
                        ProfileView(username: username)
                    }
                }
        }
    }
}
