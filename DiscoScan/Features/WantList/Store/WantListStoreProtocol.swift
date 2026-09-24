//
//  WantListStoreProtocol.swift
//  DiscoScan
//

import Foundation
import Observation

@MainActor
protocol WantListStoreProtocol: AnyObject, Observable {
    var wants: ResourceState<[WantListItem]> { get }
    var isMutating: Bool { get }
    var lastMutationError: String? { get }

    func sync(with state: AuthSession.State)
    func canLoadMore() -> Bool
    func loadWants(page: Int, forceRefresh: Bool) async
    func refreshWants() async
    func loadMoreWants() async
    func addRelease(releaseId: Int, notes: String?, rating: Int?) async
    func editRelease(releaseId: Int, notes: String?, rating: Int?) async
    func deleteRelease(releaseId: Int) async
    func isInWantList(releaseId: Int) -> Bool
    func ensureWantsLoaded() async
}

extension WantListStoreProtocol {
    func loadWants() async {
        await loadWants(page: 1, forceRefresh: false)
    }

    func loadWants(forceRefresh: Bool) async {
        await loadWants(page: 1, forceRefresh: forceRefresh)
    }

    func addRelease(releaseId: Int) async {
        await addRelease(releaseId: releaseId, notes: nil, rating: nil)
    }
}
