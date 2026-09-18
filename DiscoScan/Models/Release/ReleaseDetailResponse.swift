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

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        id = try container.decode(Int.self, forKey: .id)
        artists = try container.decode([ReleaseDetailArtist].self, forKey: .artists)
        dataQuality = try container.decode(String.self, forKey: .dataQuality)
        thumb = container.decodeDiscogsURL(forKey: .thumb)
        community = try container.decode(ReleaseDetailCommunity.self, forKey: .community)
        companies = try container.decodeDiscogsArray(ReleaseDetailCompany.self, forKey: .companies)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        dateAdded = try container.decodeIfPresent(String.self, forKey: .dateAdded)
        dateChanged = try container.decodeIfPresent(String.self, forKey: .dateChanged)
        estimatedWeight = try container.decodeIfPresent(Int.self, forKey: .estimatedWeight)
        formatQuantity = try container.decodeIfPresent(Int.self, forKey: .formatQuantity)
        formats = try container.decodeDiscogsArray(DiscogsFormat.self, forKey: .formats)
        genres = try container.decodeDiscogsArray(String.self, forKey: .genres)
        identifiers = try container.decodeDiscogsArray(ReleaseDetailIdentifier.self, forKey: .identifiers)
        images = try container.decodeDiscogsArray(ReleaseDetailImage.self, forKey: .images)
        labels = try container.decode([ReleaseDetailLabel].self, forKey: .labels)
        lowestPrice = try container.decodeIfPresent(Double.self, forKey: .lowestPrice)
        masterId = try container.decodeIfPresent(Int.self, forKey: .masterId)
        masterUrl = container.decodeDiscogsURL(forKey: .masterUrl)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        numForSale = try container.decodeIfPresent(Int.self, forKey: .numForSale)
        released = try container.decodeIfPresent(String.self, forKey: .released)
        releasedFormatted = try container.decodeIfPresent(String.self, forKey: .releasedFormatted)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
        series = try container.decodeDiscogsArray(ReleaseDetailSeries.self, forKey: .series)
        status = try container.decode(String.self, forKey: .status)
        styles = try container.decodeDiscogsArray(String.self, forKey: .styles)
        tracklist = try container.decodeDiscogsArray(ReleaseDetailTrack.self, forKey: .tracklist)
        uri = container.decodeDiscogsURL(forKey: .uri)
        videos = try container.decodeDiscogsArray(ReleaseDetailVideo.self, forKey: .videos)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
    }
}

nonisolated struct ReleaseDetailArtist: Codable, Sendable, Equatable, Identifiable {
    let anv: String
    let id: Int
    let join: String
    let name: String
    let resourceURL: URL?
    let role: String
    let tracks: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        anv = try container.decode(String.self, forKey: .anv)
        id = try container.decode(Int.self, forKey: .id)
        join = try container.decode(String.self, forKey: .join)
        name = try container.decode(String.self, forKey: .name)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
        role = try container.decode(String.self, forKey: .role)
        tracks = try container.decode(String.self, forKey: .tracks)
    }
}

nonisolated struct ReleaseDetailCommunity: Codable, Sendable, Equatable {
    let contributors: [ReleaseDetailUser]
    let dataQuality: String
    let have: Int
    let rating: ReleaseDetailRating
    let status: String
    let submitter: ReleaseDetailUser?
    let want: Int

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contributors = try container.decodeDiscogsArray(ReleaseDetailUser.self, forKey: .contributors)
        dataQuality = try container.decode(String.self, forKey: .dataQuality)
        have = try container.decode(Int.self, forKey: .have)
        rating = try container.decode(ReleaseDetailRating.self, forKey: .rating)
        status = try container.decode(String.self, forKey: .status)
        submitter = try container.decodeIfPresent(ReleaseDetailUser.self, forKey: .submitter)
        want = try container.decode(Int.self, forKey: .want)
    }
}

nonisolated struct ReleaseDetailUser: Codable, Sendable, Equatable {
    let resourceURL: URL?
    let username: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
        username = try container.decode(String.self, forKey: .username)
    }
}

nonisolated struct ReleaseDetailRating: Codable, Sendable, Equatable {
    let average: Double?
    let count: Int
}

nonisolated struct ReleaseDetailCompany: Codable, Sendable, Equatable, Identifiable {
    let catno: String
    let entityType: String
    let entityTypeName: String
    let id: Int
    let name: String
    let resourceURL: URL?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        catno = try container.decode(String.self, forKey: .catno)
        entityType = try container.decode(String.self, forKey: .entityType)
        entityTypeName = try container.decode(String.self, forKey: .entityTypeName)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
    }
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

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        height = try container.decode(Int.self, forKey: .height)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
        type = try container.decode(String.self, forKey: .type)
        uri = container.decodeDiscogsURL(forKey: .uri)
        uri150 = container.decodeDiscogsURL(forKey: .uri150)
        width = try container.decode(Int.self, forKey: .width)
    }
}

nonisolated struct ReleaseDetailLabel: Codable, Sendable, Equatable, Identifiable {
    let catno: String
    let entityType: String
    let id: Int
    let name: String
    let resourceURL: URL?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        catno = try container.decode(String.self, forKey: .catno)
        entityType = try container.decode(String.self, forKey: .entityType)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
    }
}

nonisolated struct ReleaseDetailSeries: Codable, Sendable, Equatable, Identifiable {
    let catno: String?
    let entityType: String?
    let id: Int?
    let name: String?
    let resourceURL: URL?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        catno = try container.decodeIfPresent(String.self, forKey: .catno)
        entityType = try container.decodeIfPresent(String.self, forKey: .entityType)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
    }
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
    let description: String?
    let duration: Int
    let embed: Bool
    let title: String
    let uri: URL?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        duration = try container.decode(Int.self, forKey: .duration)
        embed = try container.decode(Bool.self, forKey: .embed)
        title = try container.decode(String.self, forKey: .title)
        uri = container.decodeDiscogsURL(forKey: .uri)
    }
}
