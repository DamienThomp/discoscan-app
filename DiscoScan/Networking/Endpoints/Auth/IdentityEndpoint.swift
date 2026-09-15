//
//  IdentityEndpoint.swift
//  DiscoScan
//

import NetworkKit

nonisolated struct IdentityEndpoint: EndpointProtocol {
    typealias Response = DiscogsIdentity

    var host: APIHost { .discogs }
    var path: String { "oauth/identity" }
    var httpMethod: HTTPMethod { .get }
}
