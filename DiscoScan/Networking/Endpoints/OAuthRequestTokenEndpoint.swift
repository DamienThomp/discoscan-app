//
//  OAuthRequestTokenEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct OAuthRequestTokenEndpoint: EndpointProtocol {
    typealias Response = EmptyResponse

    let config: DiscogsConfig

    var host: APIHost { .discogs }
    var path: String { "oauth/request_token" }
    var httpMethod: HTTPMethod { .get }
    var contentType: ContentType? { .formURLEncoded }

    var headers: [String: String]? {
        [
            "Authorization": DiscogsOAuthSigner.authorizationHeader(
                consumerKey: config.consumerKey,
                consumerSecret: config.consumerSecret,
                callback: config.callbackURL.absoluteString
            )
        ]
    }
}
