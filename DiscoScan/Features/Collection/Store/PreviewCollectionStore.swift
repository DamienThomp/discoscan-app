//
//  PreviewCollectionStore.swift
//  DiscoScan
//

#if DEBUG
import Observation

enum PreviewCollectionStoreScenario {
    case foldersLoaded
    case foldersEmpty
    case foldersFailed(String)
    case foldersLoading
    case releasesLoaded(folderId: Int)
    case releasesEmpty(folderId: Int)
    case releasesFailed(folderId: Int, message: String)
    case releasesLoading(folderId: Int)
}

@MainActor
@Observable
final class PreviewCollectionStore: CollectionStoreProtocol {
    private(set) var folders: ResourceState<[CollectionFolderResponse]> = .idle
    private(set) var releasesByFolderID: [Int: ResourceState<[CollectionReleaseItem]>] = [:]
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    init(scenario: PreviewCollectionStoreScenario) {
        switch scenario {
        case .foldersLoaded:
            folders = .loaded(CollectionFixtures.sampleFolders)
        case .foldersEmpty:
            folders = .loaded([])
        case .foldersFailed(let message):
            folders = .failed(message)
        case .foldersLoading:
            folders = .loading
        case .releasesLoaded(let folderId):
            releasesByFolderID[folderId] = .loaded(CollectionFixtures.sampleReleases)
        case .releasesEmpty(let folderId):
            releasesByFolderID[folderId] = .loaded([])
        case .releasesFailed(let folderId, let message):
            releasesByFolderID[folderId] = .failed(message)
        case .releasesLoading(let folderId):
            releasesByFolderID[folderId] = .loading
        }
    }

    func sync(with state: AuthSession.State) {}

    func canLoadMore(folderId: Int) -> Bool { false }

    func loadFolders(forceRefresh: Bool) async {}

    func loadReleases(folderId: Int, page: Int, forceRefresh: Bool) async {}

    func loadMoreReleases(folderId: Int) async {}

    func createFolder(name: String) async {}

    func deleteFolder(id: Int) async {}

    func addRelease(releaseId: Int, folderId: Int) async {}

    func deleteRelease(from folderId: Int, releaseId: Int, instanceId: Int) async {}
}

@MainActor
func previewCollectionStore(_ scenario: PreviewCollectionStoreScenario) -> any CollectionStoreProtocol {
    PreviewCollectionStore(scenario: scenario)
}
#endif
