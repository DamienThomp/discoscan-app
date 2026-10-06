//
//  CollectionStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation
import os

@MainActor
@Observable
final class CollectionStore: CollectionStoreProtocol {

    private(set) var folders: ResourceState<[CollectionFolderResponse]> = .idle
    private(set) var releasesByFolderID: [Int: ResourceState<[CollectionReleaseItem]>] = [:]
    private(set) var folderZeroSync: CollectionSyncPhase = .idle
    private(set) var folderZeroItems: ResourceState<[CollectionReleaseItem]> = .idle
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    private var username: String?
    private var paginationByFolderID: [Int: SearchPagination] = [:]
    private var isLoadingMoreByFolderID: [Int: Bool] = [:]
    private var progressTask: Task<Void, Never>?

    private static let logger = Logger(subsystem: "com.discoscan", category: "CollectionStore")

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
        folderZeroItems = .idle
        folderZeroSync = .idle
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

    /// Loads the first page of a folder's releases, or ensures folder 0's local index is ready.
    /// Idempotent for page 1 without `forceRefresh`: no-ops unless state is `.idle`.
    /// Use `refreshReleases(folderId:)` to force a reload.
    func loadReleases(folderId: Int, page: Int = 1, forceRefresh: Bool = false) async {
        if folderId == .zero {
            if forceRefresh {
                await syncFolderZeroIndex(forceRefresh: true)
            } else {
                await ensureFolderZeroIndexReady()
            }
            return
        }

        if page == 1, !forceRefresh, (releasesByFolderID[folderId] ?? .idle) != .idle {
            return
        }

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
        if folderId == .zero {
            await syncFolderZeroIndex(forceRefresh: true)
            return
        }

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

            let localSucceeded = try await writeToLocalIndexWithRecovery(
                username: username,
                folderId: folderId,
                instanceId: item.instanceId,
                expectingPresent: true
            ) {
                try await localIndex.upsertLive(item, username: username)
            }

            guard localSucceeded else {
                throw CollectionStoreError.remoteAddSucceededLocalFailed
            }

            applyAddInMemoryUpdates(item: item, folderId: folderId)
            await reloadFolderZeroItems()
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

            let localSucceeded = try await writeToLocalIndexWithRecovery(
                username: username,
                folderId: folderId,
                instanceId: instanceId,
                expectingPresent: false
            ) {
                try await localIndex.delete(instanceId: instanceId, username: username)
            }

            if localSucceeded {
                applyDeleteInMemoryUpdates(folderId: folderId, instanceId: instanceId)
                await reloadFolderZeroItems()
                await loadFolders(forceRefresh: true)
            } else {
                applyDeleteInMemoryUpdates(folderId: folderId, instanceId: instanceId)
                throw CollectionStoreError.remoteDeleteSucceededLocalFailed
            }
        }
    }

    func ensureFolderZeroIndexReady() async {
        do {
            let username = try requireUsername()
            let localCount = try await localIndex.count(username: username)
            let isUnsealed = try await localIndex.hasUnsealedGeneration(username: username)

            if folders.value == nil {
                await loadFolders(forceRefresh: false)
            }

            guard let remoteTotal = folders.value?.first(where: \.isAllFolder)?.count else {
                let message = CollectionSyncError.allFolderNotFound.localizedDescription
                folderZeroItems = .failed(message)
                folderZeroSync = .failed(message)
                return
            }

            if localCount == .zero && remoteTotal > .zero {
                if folderZeroItems == .idle {
                    folderZeroItems = .loading
                }
                await syncFolderZeroIndex(forceRefresh: false)
                return
            }

            if folderZeroItems == .idle {
                await reloadFolderZeroItems()
            }

            if localCount != remoteTotal || isUnsealed {
                await syncFolderZeroIndex(forceRefresh: false)
            }
        } catch {
            folderZeroItems = folderZeroItems.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func syncFolderZeroIndex(forceRefresh: Bool = false) async {
        do {
            let username = try requireUsername()

            if forceRefresh || folders.value == nil {
                await loadFolders(forceRefresh: forceRefresh)
            }

            guard let remoteTotal = folders.value?.first(where: \.isAllFolder)?.count else {
                let message = CollectionSyncError.allFolderNotFound.localizedDescription
                folderZeroItems = .failed(message)
                folderZeroSync = .failed(message)
                return
            }

            let localCount = try await localIndex.count(username: username)
            let isUnsealed = try await localIndex.hasUnsealedGeneration(username: username)
            let needsSync = localCount != remoteTotal || isUnsealed

            if !needsSync {
                await reloadFolderZeroItems()
                return
            }

            prepareFolderZeroItemsForSync(localCount: localCount, remoteTotal: remoteTotal)

            let finalPhase = await syncService.refreshIfNeeded(
                username: username,
                forceFoldersRefresh: forceRefresh
            )
            await applyFolderZeroSyncResult(finalPhase)
        } catch {
            folderZeroItems = folderZeroItems.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func repairFolderZeroIndexIfNeeded() async {
        do {
            let username = try requireUsername()
            guard try await localIndex.hasUnsealedGeneration(username: username) else { return }
            let finalPhase = await syncService.refreshIfNeeded(
                username: username,
                forceFoldersRefresh: false
            )
            await applyFolderZeroSyncResult(finalPhase)
        } catch {
            folderZeroItems = folderZeroItems.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    func refreshCollectionIndex() async {
        await syncFolderZeroIndex(forceRefresh: true)
    }

    func searchFolderZero(query: String) -> [CollectionReleaseItem] {
        guard let items = folderZeroItems.value else { return [] }
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
                folderZeroSync = phase
                switch phase {
                case .checking:
                    folderZeroItems = folderZeroItems.beginRefresh()
                case .syncing, .idle, .failed:
                    break
                }
            }
        }
    }

    private func applyFolderZeroSyncResult(_ phase: CollectionSyncPhase) async {
        folderZeroSync = phase
        switch phase {
        case .idle:
            await reloadFolderZeroItems()
        case .failed(let message):
            folderZeroItems = folderZeroItems.recoverFromFetchFailure(message)
        case .checking, .syncing:
            break
        }
    }

    private func prepareFolderZeroItemsForSync(localCount: Int, remoteTotal: Int) {
        if localCount == .zero && remoteTotal > .zero {
            if case .idle = folderZeroItems {
                folderZeroItems = .loading
            }
        } else if let existing = folderZeroItems.value {
            folderZeroItems = .refreshing(existing)
        } else if case .idle = folderZeroItems {
            folderZeroItems = .loading
        }
    }

    private func reloadFolderZeroItems() async {
        do {
            let username = try requireUsername()
            let items = try await localIndex.allItems(username: username)
            folderZeroItems = .loaded(items)
        } catch {
            folderZeroItems = folderZeroItems.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    private func clearLocalIndex(for username: String?) async {
        guard let username else { return }
        do {
            try await localIndex.clear(username: username)
        } catch {
            // Best-effort cleanup during auth transitions; ignore.
        }
    }

    private func writeToLocalIndexWithRecovery(
        username: String,
        folderId: Int,
        instanceId: Int,
        expectingPresent: Bool,
        write: () async throws -> Void
    ) async throws -> Bool {
        do {
            try await write()
            return true
        } catch {
            do {
                try await write()
                return true
            } catch let retryError {
                Self.logger.error("Local index write failed after retry: \(retryError.localizedDescription)")
                return await repairAfterPartialMutation(
                    username: username,
                    folderId: folderId,
                    instanceId: instanceId,
                    expectingPresent: expectingPresent
                )
            }
        }
    }

    private func repairAfterPartialMutation(
        username: String,
        folderId: Int,
        instanceId: Int,
        expectingPresent: Bool
    ) async -> Bool {
        await Task.detached { @MainActor in
            await self.syncFolderZeroIndex(forceRefresh: true)
            if folderId != .zero {
                await self.refreshReleases(folderId: folderId)
            }
            await self.loadFolders(forceRefresh: true)
            return (try? await self.localIndex.contains(instanceId: instanceId, username: username))
                == expectingPresent
        }.value
    }

    private func applyAddInMemoryUpdates(item: CollectionReleaseItem, folderId: Int) {
        bumpFolderCounts(selectedFolderId: folderId, delta: 1)
        if let current = releasesByFolderID[folderId]?.value {
            releasesByFolderID[folderId] = .loaded([item] + current)
        }
    }

    private func applyDeleteInMemoryUpdates(folderId: Int, instanceId: Int) {
        bumpFolderCounts(selectedFolderId: folderId, delta: -1)
        if let current = releasesByFolderID[folderId]?.value {
            releasesByFolderID[folderId] = .loaded(
                current.filter { $0.instanceId != instanceId }
            )
        }
        if let pagination = paginationByFolderID[folderId] {
            paginationByFolderID[folderId] = pagination.afterRemovingOneItem()
        }
    }

    private func bumpFolderCounts(selectedFolderId: Int, delta: Int) {
        guard case .loaded(let folderList) = folders else { return }
        let updated = folderList.map { folder in
            guard folder.id == selectedFolderId || folder.isAllFolder else { return folder }
            return CollectionFolderResponse(
                id: folder.id,
                count: max(.zero, folder.count + delta),
                name: folder.name,
                resourceUrl: folder.resourceUrl
            )
        }
        folders = .loaded(updated)
    }

    private func performMutation(_ operation: () async throws -> Void) async {
        isMutating = true
        lastMutationError = nil
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
