//
//  ProfileStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

@MainActor
@Observable
private final class UnimplementedProfileStore: ProfileStoreProtocol {
    private(set) var profile: ResourceState<DiscogsUserProfile> = .idle

    func sync(with state: AuthSession.State) {
        fatalError("profileStore environment value was not injected.")
    }

    func loadProfile(forceRefresh: Bool) async {
        fatalError("profileStore environment value was not injected.")
    }
}

private let unimplementedProfileStore = UnimplementedProfileStore()

extension EnvironmentValues {
    @Entry var profileStore: any ProfileStoreProtocol = unimplementedProfileStore
}
