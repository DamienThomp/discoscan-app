//
//  WantListStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation
import SwiftUI

@MainActor
@Observable
final class WantListStore: WantListStoreProtocol {

    private(set) var wants: ResourceState<[WantListItem]> = .idle
    private(set) var isMutating = false
    private var mutationCount = 0
    private(set) var lastMutationError: String?
    private(set) var wantsNeedsReconcile = false

    private var username: String?
    private var pagination: SearchPagination?
    private var isLoadingMore = false
    private var wantsFetchGeneration = 0

    private let cachedFetcher: any CachedFetcherProtocol
    private let apiClient: NetworkManagerProtocol

    init(cachedFetcher: any CachedFetcherProtocol, apiClient: NetworkManagerProtocol) {
        self.cachedFetcher = cachedFetcher
        self.apiClient = apiClient
    }

    convenience init(dependencies: AppDependencies) {
        self.init(cachedFetcher: dependencies.cachedFetcher, apiClient: dependencies.apiClient)
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
        isLoadingMore = false
        mutationCount = 0
        isMutating = false
        lastMutationError = nil
        wantsNeedsReconcile = false
        wantsFetchGeneration = 0
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
            let generation = page > 1 ? wantsFetchGeneration : 0

            if page == 1 {
                wants = wants.beginRefresh()
            }

            let response = try await cachedFetcher.fetch(
                WantListEndpoint(username: username, page: page),
                key: Self.cacheKey(page: page),
                scope: .wantlist,
                forceRefresh: forceRefresh
            )
            guard self.username == username else { return }
            if page > 1, generation != wantsFetchGeneration { return }

            pagination = response.pagination

            let items = if page > 1, let existing = wants.value {
                existing + response.wants
            } else {
                response.wants
            }

            wants = .loaded(items)
        } catch {
            wants = wants.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func refreshWants() async {
        wantsFetchGeneration += 1
        await cachedFetcher.invalidateKeys(matchingPrefix: Self.wantsCachePrefix)
        isLoadingMore = false
        await loadWants(page: 1, forceRefresh: true)
    }

    func loadMoreWants() async {
        guard canLoadMore(), !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = (pagination?.page ?? 0) + 1
        await loadWants(page: nextPage, forceRefresh: false)
    }

    func addRelease(releaseId: Int, notes: String?, rating: Int?) async {
        await performMutation {
            let username = try requireUsername()
            let added = try await apiClient.request(
                for: AddReleaseToWantListEndpoint(
                    username: username,
                    releaseId: releaseId,
                    notes: notes,
                    rating: rating
                )
            )
            insertWantLocally(added)
            await refreshWants()
            wantsNeedsReconcile = !isInWantList(releaseId: releaseId)
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
            await refreshWants()
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
            if let current = wants.value {
                wants = .loaded(current.filter { $0.id != releaseId })
            }
            if let pagination {
                self.pagination = pagination.afterRemovingOneItem()
            }
        }
    }

    func isInWantList(releaseId: Int) -> Bool {
        guard let items = wants.value else {
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
        mutationCount += 1
        isMutating = true
        lastMutationError = nil
        defer {
            mutationCount -= 1
            isMutating = mutationCount > 0
        }

        do {
            try await operation()
            lastMutationError = nil
        } catch {
            lastMutationError = error.localizedDescription
        }
    }

    private func insertWantLocally(_ item: WantListItem) {
        if var current = wants.value {
            current.removeAll { $0.id == item.id }
            current.insert(item, at: 0)
            wants = .loaded(current)
        } else {
            wants = .loaded([item])
        }
    }

    private func requireUsername() throws -> String {
        guard let username else {
            throw AuthSessionError.notAuthenticated
        }
        return username
    }

    private static let wantsCachePrefix = "wants-page-"

    private static func cacheKey(page: Int) -> String {
        "\(wantsCachePrefix)\(page)"
    }
}
