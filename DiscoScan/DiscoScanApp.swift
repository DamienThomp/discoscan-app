//
//  DiscoScanApp.swift
//  DiscoScan
//

import SwiftUI

@main
struct DiscoScanApp: App {
    @State private var authSession: AuthSession
    @State private var router = AppRouter()
    private let cachedFetcher: any CachedFetcherProtocol

    init() {
        let dependencies = AppDependencies.make()
        cachedFetcher = dependencies.cachedFetcher
        _authSession = State(initialValue: AuthSession(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authSession)
                .environment(router)
                .environment(\.cachedFetcher, cachedFetcher)
                .task {
                    await authSession.bootstrap()
                }
        }
    }
}
