//
//  WantListResponse.swift
//  DiscoScan
//

import Foundation

nonisolated struct WantListResponse: Codable, Equatable, Sendable {
    let pagination: SearchPagination
    let wants: [WantListItem]
}

nonisolated struct WantListItem: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let rating: Int
    let notes: String?
    let resourceURL: URL?
    let basicInformation: ReleaseBasicInformation
}

nonisolated struct WantListItemRequestBody: Encodable, Sendable {
    let notes: String?
    let rating: Int?
}

nonisolated struct ReleaseBasicInformation: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let title: String
    let year: Int?
    let thumb: URL?
    let coverImage: URL?
    let resourceURL: URL?
    let artists: [DiscogsArtist]
    let labels: [DiscogsLabel]
    let formats: [DiscogsFormat]

    var primaryArtistName: String {
        artists.first?.name ?? "n/a"
    }

    var displayYear: Int? {
        year.displayYear
    }

    var listArtworkURL: URL? {
        coverImage ?? thumb
    }
}

nonisolated struct DiscogsArtist: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let name: String
}

nonisolated struct DiscogsLabel: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let name: String
    let catno: String?
}

nonisolated struct DiscogsFormat: Codable, Equatable, Sendable {
    let name: String
    let qty: String
    let text: String?
    let descriptions: [String]

    init(name: String, qty: String, text: String? = nil, descriptions: [String] = []) {
        self.name = name
        self.qty = qty
        self.text = text
        self.descriptions = descriptions
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        qty = try container.decode(String.self, forKey: .qty)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        descriptions = try container.decodeDiscogsArray(String.self, forKey: .descriptions)
    }
}
