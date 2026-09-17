//
//  WantListStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

@MainActor
@Observable
final class WantListStore: WantListStoreProtocol {

    private(set) var wants: ResourceState<[WantListItem]> = .idle
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    private var username: String?
    private var pagination: SearchPagination?

    private let cachedFetcher: any CachedFetcherProtocol
    private let apiClient: NetworkManagerProtocol

    init(cachedFetcher: any CachedFetcherProtocol, apiClient: NetworkManagerProtocol) {
        self.cachedFetcher = cachedFetcher
        self.apiClient = apiClient
    }

    convenience init(dependencies: AppDependencies, cachedFetcher: any CachedFetcherProtocol) {
        self.init(cachedFetcher: cachedFetcher, apiClient: dependencies.apiClient)
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

    func reset() {
        username = nil
        wants = .idle
        pagination = nil
        isMutating = false
        lastMutationError = nil
    }

    func canLoadMore() -> Bool {
        guard let pagination else {
            return false
        }
        return pagination.page < pagination.pages
    }

    func loadWants(page: Int = 1, forceRefresh: Bool = false) async {
        do {
            let username = try requireUsername()

            if page == 1 {
                wants = .loading
            }

            let response = try await cachedFetcher.fetch(
                WantListEndpoint(username: username, page: page),
                key: Self.cacheKey(page: page),
                scope: .wantlist,
                userScope: username,
                forceRefresh: forceRefresh
            )

            pagination = response.pagination

            if page == 1 {
                wants = .loaded(response.wants)
            } else if case .loaded(let existing) = wants {
                wants = .loaded(existing + response.wants)
            } else {
                wants = .loaded(response.wants)
            }
        } catch {
            wants = .failed(error.localizedDescription)
        }
    }

    func loadMoreWants() async {
        guard canLoadMore() else { return }
        let nextPage = (pagination?.page ?? 0) + 1
        await loadWants(page: nextPage, forceRefresh: false)
    }

    func addRelease(releaseId: Int, notes: String?, rating: Int?) async {
        await performMutation {
            let username = try requireUsername()
            _ = try await apiClient.request(
                for: AddReleaseToWantListEndpoint(
                    username: username,
                    releaseId: releaseId,
                    notes: notes,
                    rating: rating
                )
            )
            await loadWants(forceRefresh: true)
        }
    }

    func editRelease(releaseId: Int, notes: String?, rating: Int?) async {
        await performMutation {
            let username = try requireUsername()
            _ = try await apiClient.request(
                for: EditReleaseInWantListEndpoint(
                    username: username,
                    releaseId: releaseId,
                    notes: notes,
                    rating: rating
                )
            )
            await loadWants(forceRefresh: true)
        }
    }

    func deleteRelease(releaseId: Int) async {
        await performMutation {
            let username = try requireUsername()
            _ = try await apiClient.request(
                for: DeleteReleaseFromWantListEndpoint(
                    username: username,
                    releaseId: releaseId
                )
            )
            await loadWants(forceRefresh: true)
        }
    }

    func isInWantList(releaseId: Int) -> Bool {
        guard case .loaded(let items) = wants else {
            return false
        }
        return items.contains { $0.id == releaseId }
    }

    func ensureWantsLoaded() async {
        if wants == .idle {
            await loadWants()
        }
    }

    private func performMutation(_ operation: () async throws -> Void) async {
        isMutating = true
        defer { isMutating = false }

        do {
            try await operation()
            lastMutationError = nil
        } catch {
            lastMutationError = error.localizedDescription
        }
    }

    private func requireUsername() throws -> String {
        guard let username else {
            throw AuthSessionError.notAuthenticated
        }
        return username
    }

    private static func cacheKey(page: Int) -> String {
        "wants-page-\(page)"
    }
}
