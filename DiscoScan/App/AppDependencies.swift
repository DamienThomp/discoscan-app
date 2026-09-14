//
//  AppDependencies.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import SwiftData

struct AppDependencies {
    let config: DiscogsConfig
    let tokenStore: TokenStoreProtocol
    let handshakeClient: NetworkManagerProtocol
    let apiClient: NetworkManagerProtocol
    let oauthService: DiscogsOAuthService
    let cacheStorage: SwiftDataCacheStorage
    let cachedFetcher: CachedFetcher

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

        let rateLimitTracker = RateLimitTracker()

        let handshakeClient = NetworkManagerFactory.makeDefaultClient(
            hostResolver: hostResolver,
            customInterceptors: [UserAgentInterceptor(userAgent: config.userAgent)],
            decoder: decoder
        )

        let apiClient = NetworkManagerFactory.makeDefaultClient(
            hostResolver: hostResolver,
            customInterceptors: [
                UserAgentInterceptor(userAgent: config.userAgent),
                DiscogsOAuthInterceptor(config: config, tokenStore: tokenStore),
                DiscogsRateLimitInterceptor(tracker: rateLimitTracker)
            ],
            decoder: decoder
        )

        let oauthService = DiscogsOAuthService(
            config: config,
            handshakeClient: handshakeClient,
            tokenStore: tokenStore
        )

        let modelContainer = makeModelContainer()
        let cacheStorage = SwiftDataCacheStorage(modelContainer: modelContainer)
        let cachedFetcher = CachedFetcher(
            apiClient: apiClient,
            storage: cacheStorage,
            rateLimitTracker: rateLimitTracker,
            decoder: decoder
        )

        return AppDependencies(
            config: config,
            tokenStore: tokenStore,
            handshakeClient: handshakeClient,
            apiClient: apiClient,
            oauthService: oauthService,
            cacheStorage: cacheStorage,
            cachedFetcher: cachedFetcher
        )
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: CachedRecord.self)
        } catch {
            do {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: CachedRecord.self, configurations: configuration)
            } catch {
                fatalError("Failed to create in-memory ModelContainer: \(error)")
            }
        }
    }
}
