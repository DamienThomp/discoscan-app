//
//  CollectionFixtures.swift
//  DiscoScan
//

import Foundation

enum CollectionFixtures {
    static let sampleFolders: [CollectionFolderResponse] = [
        CollectionFolderResponse(id: 0, count: 10, name: "All", resourceUrl: "https://example.com/0"),
        CollectionFolderResponse(id: 1, count: 5, name: "Uncategorized", resourceUrl: "https://example.com/1"),
        CollectionFolderResponse(id: 2, count: 0, name: "Jazz", resourceUrl: "https://example.com/2")
    ]

    static let samplePagination = SearchPagination(page: 1, pages: 2, perPage: 50, items: 60)

    static let sampleReleases: [CollectionReleaseItem] = [
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

    static let sampleFoldersResponse = CollectionFoldersResponse(folders: sampleFolders)

    static let sampleReleasesResponse = CollectionReleasesResponse(
        pagination: samplePagination,
        releases: sampleReleases
    )

    static let previewIdentity = DiscogsIdentity(
        id: 1,
        username: "preview",
        resourceURL: nil,
        consumerName: nil
    )
}
