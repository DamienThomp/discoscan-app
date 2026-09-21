//
//  DiscoScanApp.swift
//  DiscoScan
//

import SwiftUI

@main
struct DiscoScanApp: App {

    @State private var authSession: AuthSession
    @State private var collectionStore: CollectionStore
    @State private var wantListStore: WantListStore
    @State private var releaseStore: ReleaseStore
    @State private var searchStore: SearchStore
    @State private var profileStore: ProfileStore
    @State private var router = AppRouter()

    private let cachedFetcher: any CachedFetcherProtocol
    private let sleeveIdentifier: any SleeveIdentifierProtocol

    init() {
        let dependencies = AppDependencies.make()
        cachedFetcher = dependencies.cachedFetcher
        sleeveIdentifier = dependencies.sleeveIdentifier
        _authSession = State(initialValue: AuthSession(dependencies: dependencies))
        _collectionStore = State(initialValue: CollectionStore(dependencies: dependencies))
        _wantListStore = State(initialValue: WantListStore(dependencies: dependencies))
        _releaseStore = State(initialValue: ReleaseStore(cachedFetcher: dependencies.cachedFetcher))
        _searchStore = State(initialValue: SearchStore(cachedFetcher: dependencies.cachedFetcher))
        _profileStore = State(initialValue: ProfileStore(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authSession)
                .environment(\.collectionStore, collectionStore)
                .environment(\.wantListStore, wantListStore)
                .environment(\.releaseStore, releaseStore)
                .environment(\.searchStore, searchStore)
                .environment(\.profileStore, profileStore)
                .environment(router)
                .environment(\.cachedFetcher, cachedFetcher)
                .environment(\.sleeveIdentifier, sleeveIdentifier)
                .task {
                    await authSession.bootstrap()
                }
                .onChange(of: authSession.state) { _, newState in
                    collectionStore.sync(with: newState)
                    wantListStore.sync(with: newState)
                    profileStore.sync(with: newState)
                }
                .preferredColorScheme(.dark)
        }
    }
}
