//
//  DiscogsOAuthInterceptor.swift
//  DiscoScan
//

import Foundation
import NetworkKit

actor DiscogsOAuthInterceptor: RequestInterceptor {
    private let config: DiscogsConfig
    private let tokenStore: TokenStoreProtocol

    init(config: DiscogsConfig, tokenStore: TokenStoreProtocol) {
        self.config = config
        self.tokenStore = tokenStore
    }

    func adapt(_ request: inout URLRequest) async throws {
        guard let tokens = await tokenStore.currentTokens() else {
            return
        }

        let authorization = DiscogsOAuthSigner.authorizationHeader(
            consumerKey: config.consumerKey,
            consumerSecret: config.consumerSecret,
            token: tokens.token,
            tokenSecret: tokens.tokenSecret
        )

        request.setValue(authorization, forHTTPHeaderField: "Authorization")
    }
}
