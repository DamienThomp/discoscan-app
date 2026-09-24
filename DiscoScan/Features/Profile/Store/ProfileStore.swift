//
//  ProfileStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

@MainActor
@Observable
final class ProfileStore: ProfileStoreProtocol {

    private(set) var profile: ResourceState<DiscogsUserProfile> = .idle

    private var username: String?

    private let cachedFetcher: any CachedFetcherProtocol

    init(cachedFetcher: any CachedFetcherProtocol) {
        self.cachedFetcher = cachedFetcher
    }

    convenience init(dependencies: AppDependencies) {
        self.init(cachedFetcher: dependencies.cachedFetcher)
    }

    func sync(with state: AuthSession.State) {
        switch state {
        case .authenticated(let identity):
            if username != identity.username {
                reset()
                username = identity.username
            }
        default:
            reset()
        }
    }

    func loadProfile(forceRefresh: Bool = false) async {
        do {
            let username = try requireUsername()
            profile = profile.beginRefresh()

            let response = try await cachedFetcher.fetch(
                UserProfileEndpoint(username: username),
                key: Self.cacheKey,
                scope: .profile,
                forceRefresh: forceRefresh
            )

            profile = .loaded(response)
        } catch {
            profile = profile.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    private func reset() {
        username = nil
        profile = .idle
    }

    private func requireUsername() throws -> String {
        guard let username else {
            throw AuthSessionError.notAuthenticated
        }
        return username
    }

    private static let cacheKey = "userProfile"
}
