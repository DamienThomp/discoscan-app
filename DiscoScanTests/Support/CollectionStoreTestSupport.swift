//
//  CollectionStoreTestSupport.swift
//  DiscoScanTests
//

import SwiftData
@testable import DiscoScan

@MainActor
enum CollectionStoreTestSupport {
    static func makeStore(
        fetcher: MockCollectionCachedFetcher,
        apiClient: MockCollectionNetworkClient,
        modelContainer: ModelContainer? = nil,
        localIndex: (any CollectionLocalIndexProtocol)? = nil
    ) throws -> CollectionStore {
        let container = try modelContainer ?? TestModelContainer.make()
        let index = localIndex ?? CollectionLocalIndex(modelContainer: container)
        let syncService = CollectionSyncService(index: index, cachedFetcher: fetcher)
        return CollectionStore(
            cachedFetcher: fetcher,
            apiClient: apiClient,
            localIndex: index,
            syncService: syncService
        )
    }

    static let sampleSnapshot = CollectionItemSnapshot(
        title: "Test Release",
        year: 2020,
        thumb: nil,
        coverImage: nil,
        resourceURL: nil,
        artists: [DiscogsArtist(id: 1, name: "Test Artist")],
        labels: [DiscogsLabel(id: 1, name: "Test Label", catno: "CAT-1")],
        formats: []
    )
}
