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

nonisolated enum CollectionSortOrder: String, Sendable {
    case asc
    case desc
}
