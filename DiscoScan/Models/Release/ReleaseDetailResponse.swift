//
//  ReleaseDetailResponse.swift
//  DiscoScan
//

import Foundation

nonisolated struct ReleaseDetailResponse: Codable, Sendable, Equatable {
    let title: String
    let id: Int
    let artists: [ReleaseDetailArtist]
    let dataQuality: String
    let thumb: URL?
    let community: ReleaseDetailCommunity
    let companies: [ReleaseDetailCompany]
    let country: String?
    let dateAdded: String?
    let dateChanged: String?
    let estimatedWeight: Int?
    let formatQuantity: Int?
    let formats: [DiscogsFormat]
    let genres: [String]
    let identifiers: [ReleaseDetailIdentifier]
    let images: [ReleaseDetailImage]
    let labels: [ReleaseDetailLabel]
    let lowestPrice: Double?
    let masterId: Int?
    let masterUrl: URL?
    let notes: String?
    let numForSale: Int?
    let released: String?
    let releasedFormatted: String?
    let resourceURL: URL?
    let series: [ReleaseDetailSeries]
    let status: String
    let styles: [String]
    let tracklist: [ReleaseDetailTrack]
    let uri: URL?
    let videos: [ReleaseDetailVideo]
    let year: Int?
}

nonisolated struct ReleaseDetailArtist: Codable, Sendable, Equatable, Identifiable {
    let anv: String
    let id: Int
    let join: String
    let name: String
    let resourceURL: URL?
    let role: String
    let tracks: String
}

nonisolated struct ReleaseDetailCommunity: Codable, Sendable, Equatable {
    let contributors: [ReleaseDetailUser]
    let dataQuality: String
    let have: Int
    let rating: ReleaseDetailRating
    let status: String
    let submitter: ReleaseDetailUser
    let want: Int
}

nonisolated struct ReleaseDetailUser: Codable, Sendable, Equatable {
    let resourceURL: URL?
    let username: String
}

nonisolated struct ReleaseDetailRating: Codable, Sendable, Equatable {
    let average: Double
    let count: Int
}

nonisolated struct ReleaseDetailCompany: Codable, Sendable, Equatable, Identifiable {
    let catno: String
    let entityType: String
    let entityTypeName: String
    let id: Int
    let name: String
    let resourceURL: URL?
}

nonisolated struct ReleaseDetailIdentifier: Codable, Sendable, Equatable {
    let type: String
    let value: String
}

nonisolated struct ReleaseDetailImage: Codable, Sendable, Equatable {
    let height: Int
    let resourceURL: URL?
    let type: String
    let uri: URL?
    let uri150: URL?
    let width: Int
}

nonisolated struct ReleaseDetailLabel: Codable, Sendable, Equatable, Identifiable {
    let catno: String
    let entityType: String
    let id: Int
    let name: String
    let resourceURL: URL?
}

nonisolated struct ReleaseDetailSeries: Codable, Sendable, Equatable, Identifiable {
    let catno: String?
    let entityType: String?
    let id: Int?
    let name: String?
    let resourceURL: URL?
}

nonisolated struct ReleaseDetailTrack: Codable, Sendable, Equatable {
    let duration: String?
    let position: String
    let title: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case duration
        case position
        case title
        case type = "type_"
    }
}

nonisolated struct ReleaseDetailVideo: Codable, Sendable, Equatable {
    let description: String
    let duration: Int
    let embed: Bool
    let title: String
    let uri: URL?
}
