//
//  AppDependencies.swift
//  DiscoScan
//

import Foundation
import NetworkKit

struct AppDependencies {
    let config: DiscogsConfig
    let tokenStore: TokenStoreProtocol
    let handshakeClient: NetworkManagerProtocol
    let apiClient: NetworkManagerProtocol
    let oauthService: DiscogsOAuthService

    @MainActor
    static func make() -> AppDependencies {
        let config = DiscogsConfig.fromBundle()
        let tokenStore = KeychainTokenStore()

        let hostResolver: @Sendable (APIHost) -> URL = { host in
            switch host {
            case .discogsWeb:
                URL(string: "https://www.discogs.com")!
            default:
                URL(string: "https://api.discogs.com")!
            }
        }

        let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return decoder
        }()

        let handshakeClient = NetworkManagerFactory.makeDefaultClient(
            hostResolver: hostResolver,
            customInterceptors: [UserAgentInterceptor(userAgent: config.userAgent)],
            decoder: decoder
        )

        let apiClient = NetworkManagerFactory.makeDefaultClient(
            hostResolver: hostResolver,
            customInterceptors: [
                UserAgentInterceptor(userAgent: config.userAgent),
                DiscogsOAuthInterceptor(config: config, tokenStore: tokenStore)
            ],
            decoder: decoder
        )

        let oauthService = DiscogsOAuthService(
            config: config,
            handshakeClient: handshakeClient,
            tokenStore: tokenStore
        )

        return AppDependencies(
            config: config,
            tokenStore: tokenStore,
            handshakeClient: handshakeClient,
            apiClient: apiClient,
            oauthService: oauthService
        )
    }
}
