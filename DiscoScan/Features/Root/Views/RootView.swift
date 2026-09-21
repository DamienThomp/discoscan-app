//
//  RootView.swift
//  DiscoScan
//

import SwiftUI

struct RootView: View {
    @Environment(AuthSession.self) private var authSession
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch authSession.state {
            case .bootstrapping:
                LoadingView()
            case .unauthenticated, .failed:
                LoginView()
            case .authenticating:
                LoadingView(text: "Connecting to Discogs…")
            case .authenticated:
                MainTabView()
            }
        }
        .animation(reduceMotion ? nil : .default, value: authSession.state)
        .onChange(of: authSession.state) { _, newValue in
            if case .authenticated = newValue { return }
            router.reset()
        }
    }
}
