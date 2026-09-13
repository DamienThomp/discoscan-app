//
//  SearchResponse.swift
//  DiscoScan
//

import Foundation

nonisolated struct SearchResponse: Codable, Sendable, Equatable {
    let pagination: SearchPagination
    let results: [SearchResult]
}

nonisolated struct SearchPagination: Codable, Sendable, Equatable {
    let page: Int
    let pages: Int
    let perPage: Int
    let items: Int

    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage
        case items
    }
}

nonisolated struct SearchResult: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let thumb: URL?
    let resourceURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case thumb
        case resourceURL
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        thumb = Self.decodeURL(from: container, forKey: .thumb)
        resourceURL = Self.decodeURL(from: container, forKey: .resourceURL)
    }

    private static func decodeURL(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> URL? {
        guard let string = try? container.decodeIfPresent(String.self, forKey: key),
              !string.isEmpty else {
            return nil
        }
        return URL(string: string)
    }
}
