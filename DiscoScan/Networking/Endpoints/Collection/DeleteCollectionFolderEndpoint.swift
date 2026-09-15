//
//  DeleteCollectionFolderEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct DeleteCollectionFolderEndpoint: EndpointProtocol {
    typealias Response = EmptyResponse

    let username: String
    let folderId: Int

    var host: APIHost { .discogs }
    var path: String { "users/\(username)/collection/folders/\(folderId)" }
    var httpMethod: HTTPMethod { .delete }
}
