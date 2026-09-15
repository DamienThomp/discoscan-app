//
//  CollectionStoreTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
struct CollectionStoreTests {

    private let identity = DiscogsIdentity(
        id: 1,
        username: "tester",
        resourceURL: URL(string: "https://api.discogs.com/users/tester"),
        consumerName: "DiscoScan"
    )

    private let sampleFolders = CollectionFoldersResponse(folders: [
        CollectionFolderResponse(id: 0, count: 10, name: "All", resourceUrl: "https://example.com/0"),
        CollectionFolderResponse(id: 1, count: 5, name: "Uncategorized", resourceUrl: "https://example.com/1"),
        CollectionFolderResponse(id: 2, count: 0, name: "Jazz", resourceUrl: "https://example.com/2")
    ])

    private let sampleReleases = CollectionReleasesResponse(
        pagination: SearchPagination(page: 1, pages: 2, perPage: 50, items: 60),
        releases: [
            CollectionReleaseItem(
                releaseId: 100,
                instanceId: 1000,
                folderId: 1,
                dateAdded: "2024-01-01T12:00:00-00:00",
                basicInformation: ReleaseBasicInformation(
                    id: 100,
                    title: "Test Release",
                    year: 2020,
                    thumb: nil,
                    coverImage: nil,
                    resourceURL: nil,
                    artists: [],
                    labels: [],
                    formats: []
                )
            )
        ]
    )

    @Test func syncResetsOnLogout() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()
        #expect(store.folders == .loaded(sampleFolders.folders))

        store.sync(with: .unauthenticated)
        #expect(store.folders == .idle)
        #expect(store.releasesByFolderID.isEmpty)
    }

    @Test func syncResetsWhenUsernameChanges() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        let otherIdentity = DiscogsIdentity(
            id: 2,
            username: "other",
            resourceURL: nil,
            consumerName: nil
        )
        store.sync(with: .authenticated(otherIdentity))
        #expect(store.folders == .idle)
    }

    @Test func loadFoldersTransitionsToLoaded() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadFolders()

        #expect(store.folders == .loaded(sampleFolders.folders))
        #expect(fetcher.lastFetch?.forceRefresh == false)
        #expect(fetcher.lastFetch?.key == "collectionFolders")
        #expect(fetcher.lastFetch?.userScope == "tester")
    }

    @Test func loadFoldersFailsWhenNotAuthenticated() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        await store.loadFolders()

        if case .failed = store.folders {
            #expect(Bool(true))
        } else {
            Issue.record("Expected folders to fail when unauthenticated")
        }
    }

    @Test func loadReleasesStoresPaginationAndItems() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 1)

        #expect(store.releasesByFolderID[1] == .loaded(sampleReleases.releases))
        #expect(store.canLoadMore(folderId: 1))
        #expect(fetcher.lastFetch?.key == "collectionFolder-1-page-1")
    }

    @Test func createFolderRefreshesWithForceRefresh() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.createFolder(name: "New Folder")

        #expect(apiClient.lastRequestPath?.contains("/collection/folders") == true)
        #expect(fetcher.lastFetch?.forceRefresh == true)
        #expect(store.lastMutationError == nil)
        #expect(store.isMutating == false)
    }

    @Test func deleteFolderRejectsSystemFolders() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteFolder(id: 1)

        #expect(apiClient.requestCount == 0)
        #expect(store.lastMutationError == CollectionStoreError.systemFolderNotDeletable.localizedDescription)
    }

    @Test func deleteFolderCallsEndpointAndRefreshes() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.loadReleases(folderId: 2)
        await store.deleteFolder(id: 2)

        #expect(apiClient.lastRequestPath?.contains("/collection/folders/2") == true)
        #expect(store.releasesByFolderID[2] == nil)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func addReleaseRefreshesFolderAndFolders() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.addRelease(releaseId: 249504)

        #expect(apiClient.lastRequestPath?.contains("/releases/249504") == true)
        #expect(fetcher.fetchCount >= 2)
        #expect(fetcher.lastFetch?.forceRefresh == true)
    }

    @Test func deleteReleaseRefreshesAffectedData() async {
        let fetcher = MockCollectionCachedFetcher()
        let apiClient = MockCollectionNetworkClient()
        let store = CollectionStore(cachedFetcher: fetcher, apiClient: apiClient)

        store.sync(with: .authenticated(identity))
        await store.deleteRelease(from: 1, releaseId: 100, instanceId: 1000)

        #expect(apiClient.lastRequestPath?.contains("/instances/1000") == true)
        #expect(fetcher.fetchCount >= 2)
        #expect(store.lastMutationError == nil)
    }
}

private struct MockFetchRecord: Sendable {
    let key: String
    let forceRefresh: Bool
    let userScope: String?
}

private final class MockCollectionCachedFetcher: CachedFetcherProtocol, @unchecked Sendable {
    private(set) var lastFetch: MockFetchRecord?
    private(set) var fetchCount = 0

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        fetchCount += 1
        lastFetch = MockFetchRecord(key: key, forceRefresh: forceRefresh, userScope: userScope)

        if endpoint is CollectionFoldersEndpoint {
            guard let response = CollectionFoldersResponse(folders: [
                CollectionFolderResponse(id: 0, count: 10, name: "All", resourceUrl: "https://example.com/0"),
                CollectionFolderResponse(id: 1, count: 5, name: "Uncategorized", resourceUrl: "https://example.com/1"),
                CollectionFolderResponse(id: 2, count: 0, name: "Jazz", resourceUrl: "https://example.com/2")
            ]) as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        if endpoint is CollectionItemsByFolderEndpoint {
            guard let response = CollectionReleasesResponse(
                pagination: SearchPagination(page: 1, pages: 2, perPage: 50, items: 60),
                releases: [
                    CollectionReleaseItem(
                        releaseId: 100,
                        instanceId: 1000,
                        folderId: 1,
                        dateAdded: "2024-01-01T12:00:00-00:00",
                        basicInformation: ReleaseBasicInformation(
                            id: 100,
                            title: "Test Release",
                            year: 2020,
                            thumb: nil,
                            coverImage: nil,
                            resourceURL: nil,
                            artists: [],
                            labels: [],
                            formats: []
                        )
                    )
                ]
            ) as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        throw URLError(.unsupportedURL)
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        nil
    }
}

private final class MockCollectionNetworkClient: NetworkManagerProtocol, @unchecked Sendable {
    private(set) var lastRequestPath: String?
    private(set) var requestCount = 0

    func request<E>(for endpoint: E) async throws -> E.Response where E: EndpointProtocol {
        requestCount += 1
        lastRequestPath = endpoint.path

        if E.Response.self == EmptyResponse.self {
            guard let response = EmptyResponse() as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        if E.Response.self == CollectionFolderResponse.self {
            guard let response = CollectionFolderResponse(
                id: 3,
                count: 0,
                name: "New Folder",
                resourceUrl: "https://example.com/3"
            ) as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        if E.Response.self == AddReleaseToCollectionResponse.self {
            guard let response = AddReleaseToCollectionResponse(
                instanceId: 2000,
                resourceURL: nil
            ) as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        throw URLError(.unsupportedURL)
    }

    func requestData<E>(for endpoint: E) async throws -> Data where E: EndpointProtocol {
        throw URLError(.unsupportedURL)
    }

    func response<E>(for endpoint: E) async throws -> NetworkResponse<E.Response> where E: EndpointProtocol {
        throw URLError(.unsupportedURL)
    }

    func responseData<E>(for endpoint: E) async throws -> NetworkResponse<Data> where E: EndpointProtocol {
        throw URLError(.unsupportedURL)
    }
}
