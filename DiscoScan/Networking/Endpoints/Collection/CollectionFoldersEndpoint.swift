//
//  CollectionFoldersEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct CollectionFoldersEndpoint: EndpointProtocol {
    typealias Response = CollectionFoldersResponse

    let userName: String

    var host: APIHost { .discogs }
    var path: String { "users/\(userName)/collection/folders" }
    var httpMethod: HTTPMethod { .get }
}
