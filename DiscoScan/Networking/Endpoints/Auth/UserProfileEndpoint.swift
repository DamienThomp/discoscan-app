//
//  UserProfileEndpoint.swift
//  DiscoScan
//

import NetworkKit

nonisolated struct UserProfileEndpoint: EndpointProtocol {
    typealias Response = DiscogsUserProfile

    let username: String

    var host: APIHost { .discogs }
    var path: String { "users/\(username)" }
    var httpMethod: HTTPMethod { .get }
}
