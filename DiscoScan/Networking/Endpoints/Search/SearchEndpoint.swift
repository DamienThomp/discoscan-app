//
//  SearchEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct SearchEndpoint: EndpointProtocol {
    typealias Response = SearchResponse

    enum Mode: Sendable, Equatable {
        case text(String)
        case barcode(String)
    }

    let mode: Mode
    let page: Int
    let perPage: Int

    init(text query: String, page: Int = 1, perPage: Int = 25) {
        self.mode = .text(query)
        self.page = page
        self.perPage = perPage
    }

    init(barcode code: String, page: Int = 1, perPage: Int = 25) {
        self.mode = .barcode(code)
        self.page = page
        self.perPage = perPage
    }

    var host: APIHost { .discogs }
    var path: String { "database/search" }
    var httpMethod: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        var items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        switch mode {
        case .text(let query):
            items.insert(URLQueryItem(name: "q", value: query), at: 0)
        case .barcode(let code):
            items.insert(URLQueryItem(name: "barcode", value: code), at: 0)
            items.insert(URLQueryItem(name: "type", value: "release"), at: 1)
        }

        return items
    }
}
