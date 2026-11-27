//
//  CollectionReleasesResponse.swift
//  DiscoScan
//

import Foundation

nonisolated struct CollectionReleasesResponse: Codable, Equatable, Sendable {
    let pagination: SearchPagination
    let releases: [CollectionReleaseItem]
}

nonisolated struct CollectionReleaseItem: Codable, Equatable, Sendable, Identifiable {
    let releaseId: Int
    let instanceId: Int
    let folderId: Int
    let dateAdded: String
    let basicInformation: ReleaseBasicInformation

    var id: Int { instanceId }

    enum CodingKeys: String, CodingKey {
        case releaseId = "id"
        case instanceId
        case folderId
        case dateAdded
        case basicInformation
    }
}

nonisolated struct AddReleaseToCollectionResponse: Codable, Equatable, Sendable {
    let instanceId: Int
    let resourceURL: URL?
}

nonisolated enum CollectionSortField: String, Sendable {
    case label
    case artist
    case title
    case catno
    case format
    case added
    case year
}

nonisolated enum CollectionSortOrder: String, Hashable, Sendable {
    case asc
    case desc
}

nonisolated enum FolderZeroSortField: String, Hashable, Sendable, CaseIterable {
    case dateAdded
    case artist
    case title
}

nonisolated struct CollectionSortOption: Hashable, Sendable {
    var field: FolderZeroSortField
    var direction: CollectionSortOrder

    static let newestFirst = CollectionSortOption(field: .dateAdded, direction: .desc)
    static let oldestFirst = CollectionSortOption(field: .dateAdded, direction: .asc)
    static let artistAZ = CollectionSortOption(field: .artist, direction: .asc)
    static let artistZA = CollectionSortOption(field: .artist, direction: .desc)
    static let titleAZ = CollectionSortOption(field: .title, direction: .asc)
    static let titleZA = CollectionSortOption(field: .title, direction: .desc)

    var title: String {
        switch (field, direction) {
        case (.dateAdded, .desc): "Newest first"
        case (.dateAdded, .asc): "Oldest first"
        case (.artist, .asc): "Artist A–Z"
        case (.artist, .desc): "Artist Z–A"
        case (.title, .asc): "Title A–Z"
        case (.title, .desc): "Title Z–A"
        }
    }
}
