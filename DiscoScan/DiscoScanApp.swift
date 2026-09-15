//
//  DiscoScanApp.swift
//  DiscoScan
//

import SwiftUI

@main
struct DiscoScanApp: App {

    @State private var authSession: AuthSession
    @State private var collectionStore: CollectionStore
    @State private var router = AppRouter()

    private let cachedFetcher: any CachedFetcherProtocol

    init() {
        let dependencies = AppDependencies.make()
        cachedFetcher = dependencies.cachedFetcher
        _authSession = State(initialValue: AuthSession(dependencies: dependencies))
        _collectionStore = State(
            initialValue: CollectionStore(
                dependencies: dependencies,
                cachedFetcher: dependencies.cachedFetcher
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authSession)
                .environment(collectionStore)
                .environment(router)
                .environment(\.cachedFetcher, cachedFetcher)
                .task {
                    await authSession.bootstrap()
                }
                .onChange(of: authSession.state) { _, newState in
                    collectionStore.sync(with: newState)
                }
                .preferredColorScheme(.dark)
        }
    }
}
