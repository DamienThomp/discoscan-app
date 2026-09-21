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

    func afterRemovingOneItem() -> SearchPagination {
        let newItems = max(0, items - 1)
        let newPages = max(1, (newItems + perPage - 1) / perPage)
        return SearchPagination(page: page, pages: newPages, perPage: perPage, items: newItems)
    }
}

nonisolated struct SearchResult: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let thumb: URL?
    let resourceURL: URL?
    let format: [String]?
    let catno: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case thumb
        case resourceURL
        case format
        case catno
    }

    init(
        id: Int,
        type: String,
        title: String,
        thumb: URL? = nil,
        resourceURL: URL? = nil,
        format: [String]? = nil,
        catno: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.thumb = thumb
        self.resourceURL = resourceURL
        self.format = format
        self.catno = catno
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        thumb = container.decodeDiscogsURL(forKey: .thumb)
        resourceURL = container.decodeDiscogsURL(forKey: .resourceURL)
        format = try container.decodeIfPresent([String].self, forKey: .format)
        catno = try container.decodeIfPresent(String.self, forKey: .catno)
    }
}
