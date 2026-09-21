//
//  CollectionStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

@MainActor
@Observable
final class CollectionStore: CollectionStoreProtocol {

    private(set) var folders: ResourceState<[CollectionFolderResponse]> = .idle
    private(set) var releasesByFolderID: [Int: ResourceState<[CollectionReleaseItem]>] = [:]
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    private var username: String?
    private var paginationByFolderID: [Int: SearchPagination] = [:]
    private var isLoadingMoreByFolderID: [Int: Bool] = [:]

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
        folders = .idle
        releasesByFolderID = [:]
        paginationByFolderID = [:]
        isLoadingMoreByFolderID = [:]
        isMutating = false
        lastMutationError = nil
    }

    func canLoadMore(folderId: Int) -> Bool {
        guard let pagination = paginationByFolderID[folderId] else {
            return false
        }
        return pagination.page < pagination.pages
    }

    func loadFolders(forceRefresh: Bool = false) async {
        do {
            let username = try requireUsername()
            folders = folders.beginRefresh()

            let response = try await cachedFetcher.fetch(
                CollectionFoldersEndpoint(userName: username),
                key: Self.foldersCacheKey,
                scope: .collection,
                userScope: username,
                forceRefresh: forceRefresh
            )

            folders = .loaded(response.folders)
        } catch {
            folders = folders.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func loadReleases(folderId: Int, page: Int = 1, forceRefresh: Bool = false) async {
        do {
            let username = try requireUsername()

            if page == 1 {
                releasesByFolderID[folderId] = (releasesByFolderID[folderId] ?? .idle).beginRefresh()
            }

            let response = try await cachedFetcher.fetch(
                CollectionItemsByFolderEndpoint(username: username, folderId: folderId, page: page),
                key: Self.releasesCacheKey(folderId: folderId, page: page),
                scope: .collection,
                userScope: username,
                forceRefresh: forceRefresh
            )

            paginationByFolderID[folderId] = response.pagination

            if page == 1 {
                releasesByFolderID[folderId] = .loaded(response.releases)
            } else if let existing = releasesByFolderID[folderId]?.value {
                releasesByFolderID[folderId] = .loaded(existing + response.releases)
            } else {
                releasesByFolderID[folderId] = .loaded(response.releases)
            }
        } catch {
            let current = releasesByFolderID[folderId] ?? .idle
            releasesByFolderID[folderId] = current.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func loadMoreReleases(folderId: Int) async {
        guard canLoadMore(folderId: folderId),
              isLoadingMoreByFolderID[folderId] != true else { return }

        isLoadingMoreByFolderID[folderId] = true
        defer { isLoadingMoreByFolderID[folderId] = false }

        let nextPage = (paginationByFolderID[folderId]?.page ?? 0) + 1
        await loadReleases(folderId: folderId, page: nextPage, forceRefresh: false)
    }

    func createFolder(name: FolderName) async throws {
        let username = try requireUsername()
        _ = try await apiClient.request(
            for: CreateCollectionFolderEndpoint(username: username, name: name.value)
        )
        await loadFolders(forceRefresh: true)
    }

    func deleteFolder(id folderId: Int) async {
        guard folderId >= 2 else {
            lastMutationError = CollectionStoreError.systemFolderNotDeletable.localizedDescription
            return
        }

        await performMutation {
            let username = try requireUsername()
            _ = try await apiClient.request(
                for: DeleteCollectionFolderEndpoint(username: username, folderId: folderId)
            )
            releasesByFolderID.removeValue(forKey: folderId)
            paginationByFolderID.removeValue(forKey: folderId)
            isLoadingMoreByFolderID.removeValue(forKey: folderId)
            await loadFolders(forceRefresh: true)
        }
    }

    func addRelease(releaseId: Int, folderId: Int = 1) async {
        await performMutation {
            let username = try requireUsername()
            _ = try await apiClient.request(
                for: AddReleaseToCollectionEndpoint(
                    username: username,
                    folderId: folderId,
                    releaseId: releaseId
                )
            )
            await loadReleases(folderId: folderId, forceRefresh: true)
            await loadFolders(forceRefresh: true)
        }
    }

    func deleteRelease(from folderId: Int, releaseId: Int, instanceId: Int) async {
        await performMutation {
            let username = try requireUsername()
            _ = try await apiClient.request(
                for: DeleteCollectionReleaseEndpoint(
                    username: username,
                    folderId: folderId,
                    releaseId: releaseId,
                    instanceId: instanceId
                )
            )
            if let current = releasesByFolderID[folderId]?.value {
                releasesByFolderID[folderId] = .loaded(
                    current.filter { $0.instanceId != instanceId }
                )
            }
            if let pagination = paginationByFolderID[folderId] {
                paginationByFolderID[folderId] = pagination.afterRemovingOneItem()
            }
            await loadFolders(forceRefresh: true)
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

    private static let foldersCacheKey = "collectionFolders"

    private static func releasesCacheKey(folderId: Int, page: Int) -> String {
        "collectionFolder-\(folderId)-page-\(page)"
    }
}
