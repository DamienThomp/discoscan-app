//
//  CollectionItemsByFolderEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct CollectionItemsByFolderEndpoint: EndpointProtocol {
    typealias Response = CollectionReleasesResponse

    let username: String
    let folderId: Int
    let page: Int
    let perPage: Int
    let sort: CollectionSortField
    let sortOrder: CollectionSortOrder

    init(
        username: String,
        folderId: Int,
        page: Int = 1,
        perPage: Int = 50,
        sort: CollectionSortField = .artist,
        sortOrder: CollectionSortOrder = .asc
    ) {
        self.username = username
        self.folderId = folderId
        self.page = page
        self.perPage = perPage
        self.sort = sort
        self.sortOrder = sortOrder
    }

    var host: APIHost { .discogs }
    var path: String { "users/\(username)/collection/folders/\(folderId)/releases" }
    var httpMethod: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "sort_order", value: sortOrder.rawValue)
        ]
    }
}
