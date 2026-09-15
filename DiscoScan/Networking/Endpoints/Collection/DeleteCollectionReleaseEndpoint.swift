//
//  DeleteCollectionReleaseEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct DeleteCollectionReleaseEndpoint: EndpointProtocol {
    typealias Response = EmptyResponse

    let username: String
    let folderId: Int
    let releaseId: Int
    let instanceId: Int

    var host: APIHost { .discogs }
    var path: String {
        "users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)/instances/\(instanceId)"
    }
    var httpMethod: HTTPMethod { .delete }
}
