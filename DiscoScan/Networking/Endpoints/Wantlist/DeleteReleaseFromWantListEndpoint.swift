//
//  DeleteReleaseFromWantListEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct DeleteReleaseFromWantListEndpoint: EndpointProtocol {
    typealias Response = EmptyResponse

    let username: String
    let releaseId: Int

    var host: APIHost { .discogs }
    var path: String { "users/\(username)/wants/\(releaseId)" }
    var httpMethod: HTTPMethod { .delete }
}
