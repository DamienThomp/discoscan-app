//
//  SearchEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct SearchEndpoint: EndpointProtocol {
    typealias Response = SearchResponse

    let query: String
    let page: Int
    let perPage: Int

    init(query: String, page: Int = 1, perPage: Int = 25) {
        self.query = query
        self.page = page
        self.perPage = perPage
    }

    var host: APIHost { .discogs }
    var path: String { "database/search" }
    var httpMethod: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
    }
}
