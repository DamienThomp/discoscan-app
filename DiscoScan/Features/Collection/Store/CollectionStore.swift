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
    private(set) var folder0Sync: CollectionSyncPhase = .idle
    private(set) var folder0Items: ResourceState<[CollectionReleaseItem]> = .idle
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    private var username: String?
    private var paginationByFolderID: [Int: SearchPagination] = [:]
    private var isLoadingMoreByFolderID: [Int: Bool] = [:]
    private var progressTask: Task<Void, Never>?

    private let cachedFetcher: any CachedFetcherProtocol
    private let apiClient: NetworkManagerProtocol
    private let localIndex: any CollectionLocalIndexProtocol
    private let syncService: any CollectionSyncServiceProtocol

    init(
        cachedFetcher: any CachedFetcherProtocol,
        apiClient: NetworkManagerProtocol,
        localIndex: any CollectionLocalIndexProtocol,
        syncService: any CollectionSyncServiceProtocol
    ) {
        self.cachedFetcher = cachedFetcher
        self.apiClient = apiClient
        self.localIndex = localIndex
        self.syncService = syncService
        subscribeToSyncProgress()
    }

    convenience init(dependencies: AppDependencies) {
        self.init(
            cachedFetcher: dependencies.cachedFetcher,
            apiClient: dependencies.apiClient,
            localIndex: dependencies.collectionLocalIndex,
            syncService: dependencies.collectionSyncService
        )
    }

    func sync(with state: AuthSession.State) {
        switch state {
        case .authenticated(let identity):
            if username != identity.username {
                Task { await clearLocalIndex(for: username) }
                reset()
                username = identity.username
            }
        default:
            Task { await clearLocalIndex(for: username) }
            reset()
        }
    }

    func reset() {
        progressTask?.cancel()
        progressTask = nil
        username = nil
        folders = .idle
        releasesByFolderID = [:]
        folder0Items = .idle
        folder0Sync = .idle
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
                forceRefresh: forceRefresh
            )

            paginationByFolderID[folderId] = response.pagination

            let releases = if page > 1, let existing = releasesByFolderID[folderId]?.value {
                existing + response.releases
            } else {
                response.releases
            }

            releasesByFolderID[folderId] = .loaded(releases)
        } catch {
            let current = releasesByFolderID[folderId] ?? .idle
            releasesByFolderID[folderId] = current.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func refreshReleases(folderId: Int) async {
        await cachedFetcher.invalidateKeys(matchingPrefix: Self.releasesCachePrefix(folderId: folderId))
        isLoadingMoreByFolderID.removeValue(forKey: folderId)
        await loadReleases(folderId: folderId, page: 1, forceRefresh: true)
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

    func addRelease(releaseId: Int, folderId: Int = 1, snapshot: CollectionItemSnapshot) async {
        await performMutation {
            let username = try requireUsername()
            let response = try await apiClient.request(
                for: AddReleaseToCollectionEndpoint(
                    username: username,
                    folderId: folderId,
                    releaseId: releaseId
                )
            )
            let item = snapshot.asCollectionReleaseItem(
                releaseId: releaseId,
                instanceId: response.instanceId,
                folderId: folderId,
                dateAdded: Self.currentISO8601Date()
            )
            try await localIndex.upsertLive(item, username: username)
            bumpFolderCounts(selectedFolderId: folderId, delta: 1)
            if let current = releasesByFolderID[folderId]?.value {
                releasesByFolderID[folderId] = .loaded([item] + current)
            }
            await reloadFolder0Items()
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
            try await localIndex.delete(instanceId: instanceId, username: username)
            bumpFolderCounts(selectedFolderId: folderId, delta: -1)
            if let current = releasesByFolderID[folderId]?.value {
                releasesByFolderID[folderId] = .loaded(
                    current.filter { $0.instanceId != instanceId }
                )
            }
            if let pagination = paginationByFolderID[folderId] {
                paginationByFolderID[folderId] = pagination.afterRemovingOneItem()
            }
            await reloadFolder0Items()
            await loadFolders(forceRefresh: true)
        }
    }

    func ensureFolder0IndexReady() async {
        guard let username = try? requireUsername() else { return }

        if (try? await localIndex.hasUnsealedGeneration(username: username)) == true {
            startBackgroundSync(username: username, forceFoldersRefresh: false)
        }

        if folder0Items == .idle {
            await reloadFolder0Items()
        }

        let count = try? await localIndex.count(username: username)
        if count == 0 {
            startBackgroundSync(username: username, forceFoldersRefresh: false)
        }
    }

    func refreshCollectionIndex() async {
        guard let username = try? requireUsername() else { return }

        folder0Sync = .checking
        await loadFolders(forceRefresh: true)

        guard let remoteTotal = folders.value?.first(where: { $0.id == 0 })?.count else {
            folder0Sync = .idle
            return
        }

        let localTotal = (try? await localIndex.count(username: username)) ?? 0
        let isUnsealed = (try? await localIndex.hasUnsealedGeneration(username: username)) ?? false
        folder0Sync = .idle

        if remoteTotal != localTotal || isUnsealed {
            startBackgroundSync(username: username, forceFoldersRefresh: false)
        }
    }

    func searchFolder0(query: String) -> [CollectionReleaseItem] {
        guard let items = folder0Items.value else { return [] }
        return items.filter { item in
            let searchable = LocalCollectionItem.makeSearchableText(
                artist: item.basicInformation.primaryArtistName,
                title: item.basicInformation.title,
                label: item.basicInformation.labels.first?.name ?? "",
                catno: item.basicInformation.labels.first?.catno ?? "",
                year: item.basicInformation.year
            )
            return CollectionSearchMatching.matches(query: query, searchableText: searchable)
        }
    }

    private func subscribeToSyncProgress() {
        progressTask = Task { [weak self] in
            guard let self else { return }
            let stream = await syncService.progressStream()
            for await phase in stream {
                guard !Task.isCancelled else { return }
                folder0Sync = phase
                if phase == .idle {
                    await reloadFolder0Items()
                }
            }
        }
    }

    private func startBackgroundSync(username: String, forceFoldersRefresh: Bool) {
        Task {
            await syncService.refreshIfNeeded(
                username: username,
                forceFoldersRefresh: forceFoldersRefresh
            )
        }
    }

    private func reloadFolder0Items() async {
        guard let username = try? requireUsername() else { return }
        do {
            let items = try await localIndex.allItems(username: username)
            folder0Items = .loaded(items)
        } catch {
            folder0Items = folder0Items.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    private func clearLocalIndex(for username: String?) async {
        guard let username else { return }
        try? await localIndex.clear(username: username)
    }

    private func bumpFolderCounts(selectedFolderId: Int, delta: Int) {
        guard case .loaded(let folderList) = folders else { return }
        let updated = folderList.map { folder in
            guard folder.id == selectedFolderId || folder.id == 0 else { return folder }
            return CollectionFolderResponse(
                id: folder.id,
                count: max(0, folder.count + delta),
                name: folder.name,
                resourceUrl: folder.resourceUrl
            )
        }
        folders = .loaded(updated)
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

    private static func currentISO8601Date() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static let foldersCacheKey = "collectionFolders"

    private static func releasesCacheKey(folderId: Int, page: Int) -> String {
        "collectionFolder-\(folderId)-page-\(page)"
    }

    private static func releasesCachePrefix(folderId: Int) -> String {
        "collectionFolder-\(folderId)-page-"
    }
}
