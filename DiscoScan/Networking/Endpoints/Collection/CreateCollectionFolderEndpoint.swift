//
//  CreateCollectionFolderEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct CreateCollectionFolderEndpoint: EndpointProtocol {
    typealias Response = CollectionFolderResponse

    let username: String
    let name: String

    var host: APIHost { .discogs }
    var path: String { "users/\(username)/collection/folders" }
    var httpMethod: HTTPMethod { .post }
    var body: (any Encodable & Sendable)? { CreateCollectionFolderRequestBody(name: name) }
}

private nonisolated struct CreateCollectionFolderRequestBody: Encodable, Sendable {
    let name: String
}
