//
//  ProfileStoreProtocol.swift
//  DiscoScan
//

import Foundation
import Observation

@MainActor
protocol ProfileStoreProtocol: AnyObject, Observable {
    var profile: ResourceState<DiscogsUserProfile> { get }

    func sync(with state: AuthSession.State)
    func loadProfile(forceRefresh: Bool) async
}

extension ProfileStoreProtocol {
    func loadProfile() async {
        await loadProfile(forceRefresh: false)
    }
}
