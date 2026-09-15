//
//  WantListEndpoint.swift
//  DiscoScan
//
//  Created by Damien L Thompson on 2026-09-15.
//

import Foundation
import NetworkKit

nonisolated struct WantListEndpoint: EndpointProtocol {
    typealias Response = WantListResponse

    let username: String
    let page: Int
    let perPage: Int

    init(username: String, page: Int = 1, perPage: Int = 50) {
        self.username = username
        self.page = page
        self.perPage = perPage
    }

    var host: APIHost { .discogs }
    var path: String { "users/\(username)/wants" }
    var httpMethod: HTTPMethod { .get }
}

