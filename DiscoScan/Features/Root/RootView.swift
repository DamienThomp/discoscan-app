//
//  RootView.swift
//  DiscoScan
//

import SwiftUI

struct RootView: View {
    @Environment(AuthSession.self) private var authSession
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            switch authSession.state {
            case .bootstrapping:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .unauthenticated, .failed:
                LoginView()
            case .authenticating:
                ProgressView("Connecting to Discogs…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.default, value: authSession.state)
        .onChange(of: authSession.state) { _, newValue in
            if case .authenticated = newValue { return }
            router.reset()
        }
    }
}
