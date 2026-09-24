//
//  CollectionStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

@MainActor
@Observable
private final class UnimplementedCollectionStore: CollectionStoreProtocol {
    private(set) var folders: ResourceState<[CollectionFolderResponse]> = .idle
    private(set) var releasesByFolderID: [Int: ResourceState<[CollectionReleaseItem]>] = [:]
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    func sync(with state: AuthSession.State) {
        fatalError("collectionStore environment value was not injected.")
    }

    func canLoadMore(folderId: Int) -> Bool {
        fatalError("collectionStore environment value was not injected.")
    }

    func loadFolders(forceRefresh: Bool) async {
        fatalError("collectionStore environment value was not injected.")
    }

    func loadReleases(folderId: Int, page: Int, forceRefresh: Bool) async {
        fatalError("collectionStore environment value was not injected.")
    }

    func refreshReleases(folderId: Int) async {
        fatalError("collectionStore environment value was not injected.")
    }

    func loadMoreReleases(folderId: Int) async {
        fatalError("collectionStore environment value was not injected.")
    }

    func createFolder(name: FolderName) async throws {
        fatalError("collectionStore environment value was not injected.")
    }

    func deleteFolder(id: Int) async {
        fatalError("collectionStore environment value was not injected.")
    }

    func addRelease(releaseId: Int, folderId: Int) async {
        fatalError("collectionStore environment value was not injected.")
    }

    func deleteRelease(from folderId: Int, releaseId: Int, instanceId: Int) async {
        fatalError("collectionStore environment value was not injected.")
    }
}

private let unimplementedCollectionStore = UnimplementedCollectionStore()

extension EnvironmentValues {
    @Entry var collectionStore: any CollectionStoreProtocol = unimplementedCollectionStore
}
