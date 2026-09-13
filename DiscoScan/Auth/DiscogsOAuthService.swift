//
//  DiscogsOAuthService.swift
//  DiscoScan
//

import Foundation
import NetworkKit

@MainActor
final class DiscogsOAuthService {
    private let config: DiscogsConfig
    private let handshakeClient: NetworkManagerProtocol
    private let tokenStore: TokenStoreProtocol
    private let webAuthPresenter: WebAuthPresenter

    init(
        config: DiscogsConfig,
        handshakeClient: NetworkManagerProtocol,
        tokenStore: TokenStoreProtocol,
        webAuthPresenter: WebAuthPresenter = .shared
    ) {
        self.config = config
        self.handshakeClient = handshakeClient
        self.tokenStore = tokenStore
        self.webAuthPresenter = webAuthPresenter
    }

    func performLogin() async throws -> OAuthTokens {
        let requestTokens = try await fetchRequestToken()
        let verifier = try await authorize(requestToken: requestTokens.token)
        let accessTokens = try await exchangeAccessToken(
            requestToken: requestTokens.token,
            requestTokenSecret: requestTokens.tokenSecret,
            verifier: verifier
        )
        try await tokenStore.save(accessTokens)
        return accessTokens
    }

    func fetchRequestToken() async throws -> OAuthRequestTokens {
        let data = try await handshakeClient.requestData(for: OAuthRequestTokenEndpoint(config: config))
        return try FormURLEncodedParser.requestTokens(from: data)
    }

    func authorize(requestToken: String) async throws -> String {
        var components = URLComponents(string: "https://www.discogs.com/oauth/authorize")
        components?.queryItems = [URLQueryItem(name: "oauth_token", value: requestToken)]

        guard let authorizeURL = components?.url else {
            throw URLError(.badURL)
        }

        return try await webAuthPresenter.authorize(
            url: authorizeURL,
            callbackScheme: config.callbackURLScheme
        )
    }

    func exchangeAccessToken(
        requestToken: String,
        requestTokenSecret: String,
        verifier: String
    ) async throws -> OAuthTokens {
        let endpoint = OAuthAccessTokenEndpoint(
            config: config,
            requestToken: requestToken,
            requestTokenSecret: requestTokenSecret,
            verifier: verifier
        )
        let data = try await handshakeClient.requestData(for: endpoint)
        return try FormURLEncodedParser.oauthTokens(from: data)
    }
}
