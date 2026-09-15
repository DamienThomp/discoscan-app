//
//  CollectionStoreProtocol.swift
//  DiscoScan
//

import Foundation
import Observation

enum ResourceState<T: Equatable & Sendable>: Equatable, Sendable {
    case idle
    case loading
    case loaded(T)
    case failed(String)
}

enum CollectionStoreError: LocalizedError, Equatable {
    case systemFolderNotDeletable

    var errorDescription: String? {
        switch self {
        case .systemFolderNotDeletable:
            "System folders cannot be deleted."
        }
    }
}

@MainActor
protocol CollectionStoreProtocol: AnyObject, Observable {
    var folders: ResourceState<[CollectionFolderResponse]> { get }
    var releasesByFolderID: [Int: ResourceState<[CollectionReleaseItem]>] { get }
    var isMutating: Bool { get }
    var lastMutationError: String? { get }

    func sync(with state: AuthSession.State)
    func canLoadMore(folderId: Int) -> Bool
    func loadFolders(forceRefresh: Bool) async
    func loadReleases(folderId: Int, page: Int, forceRefresh: Bool) async
    func loadMoreReleases(folderId: Int) async
    func createFolder(name: String) async
    func deleteFolder(id: Int) async
    func addRelease(releaseId: Int, folderId: Int) async
    func deleteRelease(from folderId: Int, releaseId: Int, instanceId: Int) async
}

extension CollectionStoreProtocol {
    func loadFolders() async {
        await loadFolders(forceRefresh: false)
    }

    func loadReleases(folderId: Int) async {
        await loadReleases(folderId: folderId, page: 1, forceRefresh: false)
    }

    func loadReleases(folderId: Int, forceRefresh: Bool) async {
        await loadReleases(folderId: folderId, page: 1, forceRefresh: forceRefresh)
    }

    func addRelease(releaseId: Int) async {
        await addRelease(releaseId: releaseId, folderId: 1)
    }
}
