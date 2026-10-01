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
    case folderZeroLoaded
    case folderZeroSyncing
}

@MainActor
@Observable
final class PreviewCollectionStore: CollectionStoreProtocol {
    private(set) var folders: ResourceState<[CollectionFolderResponse]> = .idle
    private(set) var releasesByFolderID: [Int: ResourceState<[CollectionReleaseItem]>] = [:]
    private(set) var folderZeroSync: CollectionSyncPhase = .idle
    private(set) var folderZeroItems: ResourceState<[CollectionReleaseItem]> = .idle
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
        case .folderZeroLoaded:
            folderZeroItems = .loaded(CollectionFixtures.sampleReleases)
        case .folderZeroSyncing:
            folderZeroItems = .loaded(CollectionFixtures.sampleReleases)
            folderZeroSync = .syncing(synced: 450, total: 2100)
        }
    }

    func sync(with state: AuthSession.State) {}

    func canLoadMore(folderId: Int) -> Bool { false }

    func loadFolders(forceRefresh: Bool) async {}

    func loadReleases(folderId: Int, page: Int, forceRefresh: Bool) async {}

    func refreshReleases(folderId: Int) async {}

    func loadMoreReleases(folderId: Int) async {}

    func createFolder(name: FolderName) async throws {}

    func deleteFolder(id: Int) async {}

    func addRelease(releaseId: Int, folderId: Int, snapshot: CollectionItemSnapshot) async {}

    func deleteRelease(from folderId: Int, releaseId: Int, instanceId: Int) async {}

    func ensureFolderZeroIndexReady() async {}

    func syncFolderZeroIndex(forceRefresh: Bool) async {}

    func repairFolderZeroIndexIfNeeded() async {}

    func refreshCollectionIndex() async {}

    func searchFolderZero(query: String) -> [CollectionReleaseItem] {
        guard let items = folderZeroItems.value else { return [] }
        guard !query.isEmpty else { return items }
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
}

@MainActor
func previewCollectionStore(_ scenario: PreviewCollectionStoreScenario) -> any CollectionStoreProtocol {
    PreviewCollectionStore(scenario: scenario)
}
#endif
