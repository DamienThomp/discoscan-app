//
//  WantListStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

@MainActor
@Observable
private final class UnimplementedWantListStore: WantListStoreProtocol {
    private(set) var wants: ResourceState<[WantListItem]> = .idle
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    func sync(with state: AuthSession.State) {
        fatalError("wantListStore environment value was not injected.")
    }

    func canLoadMore() -> Bool {
        fatalError("wantListStore environment value was not injected.")
    }

    func loadWants(page: Int, forceRefresh: Bool) async {
        fatalError("wantListStore environment value was not injected.")
    }

    func loadMoreWants() async {
        fatalError("wantListStore environment value was not injected.")
    }

    func addRelease(releaseId: Int, notes: String?, rating: Int?) async {
        fatalError("wantListStore environment value was not injected.")
    }

    func editRelease(releaseId: Int, notes: String?, rating: Int?) async {
        fatalError("wantListStore environment value was not injected.")
    }

    func deleteRelease(releaseId: Int) async {
        fatalError("wantListStore environment value was not injected.")
    }

    func isInWantList(releaseId: Int) -> Bool {
        fatalError("wantListStore environment value was not injected.")
    }

    func ensureWantsLoaded() async {
        fatalError("wantListStore environment value was not injected.")
    }
}

private let unimplementedWantListStore = UnimplementedWantListStore()

extension EnvironmentValues {
    @Entry var wantListStore: any WantListStoreProtocol = unimplementedWantListStore
}
