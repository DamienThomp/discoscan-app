//
//  OAuthAccessTokenEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct OAuthAccessTokenEndpoint: EndpointProtocol {
    typealias Response = EmptyResponse

    let config: DiscogsConfig
    let requestToken: String
    let requestTokenSecret: String
    let verifier: String

    var host: APIHost { .discogs }
    var path: String { "oauth/access_token" }
    var httpMethod: HTTPMethod { .post }
    var contentType: ContentType? { .formURLEncoded }

    var headers: [String: String]? {
        [
            "Authorization": DiscogsOAuthSigner.authorizationHeader(
                consumerKey: config.consumerKey,
                consumerSecret: config.consumerSecret,
                token: requestToken,
                tokenSecret: requestTokenSecret,
                verifier: verifier
            )
        ]
    }
}
