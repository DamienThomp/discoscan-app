//
//  AppDependencies.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import SwiftData

struct AppDependencies {
    let config: DiscogsConfig
    let geminiConfig: GeminiConfig
    let tokenStore: TokenStoreProtocol
    let handshakeClient: NetworkManagerProtocol
    let apiClient: NetworkManagerProtocol
    let oauthService: DiscogsOAuthService
    let cacheStorage: SwiftDataCacheStorage
    let collectionLocalIndex: CollectionLocalIndex
    let collectionSyncService: CollectionSyncService
    let cachedFetcher: CachedFetcher
    let sleeveIdentifier: GeminiSleeveIdentifier
    let appleMusicCatalog: AppleMusicCatalogService

    @MainActor
    static func make() -> AppDependencies {
        let config = DiscogsConfig.fromBundle()
        let geminiConfig = GeminiConfig.fromBundle()
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

        let webAuthPresenter = WebAuthPresenter()
        let oauthService = DiscogsOAuthService(
            config: config,
            handshakeClient: handshakeClient,
            tokenStore: tokenStore,
            webAuthPresenter: webAuthPresenter
        )

        let modelContainer = makeModelContainer()
        let cacheStorage = SwiftDataCacheStorage(modelContainer: modelContainer)
        let collectionLocalIndex = CollectionLocalIndex(modelContainer: modelContainer)
        let cachedFetcher = CachedFetcher(
            apiClient: apiClient,
            storage: cacheStorage,
            rateLimitTracker: rateLimitTracker,
            decoder: decoder
        )
        let collectionSyncService = CollectionSyncService(
            index: collectionLocalIndex,
            cachedFetcher: cachedFetcher
        )

        let sleeveIdentifier = GeminiSleeveIdentifier(config: geminiConfig)
        let appleMusicCatalog = AppleMusicCatalogService()

        return AppDependencies(
            config: config,
            geminiConfig: geminiConfig,
            tokenStore: tokenStore,
            handshakeClient: handshakeClient,
            apiClient: apiClient,
            oauthService: oauthService,
            cacheStorage: cacheStorage,
            collectionLocalIndex: collectionLocalIndex,
            collectionSyncService: collectionSyncService,
            cachedFetcher: cachedFetcher,
            sleeveIdentifier: sleeveIdentifier,
            appleMusicCatalog: appleMusicCatalog
        )
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: CachedRecord.self,
                LocalCollectionItem.self,
                CollectionSyncMetadata.self
            )
        } catch {
            do {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(
                    for: CachedRecord.self,
                    LocalCollectionItem.self,
                    CollectionSyncMetadata.self,
                    configurations: configuration
                )
            } catch {
                fatalError("Failed to create in-memory ModelContainer: \(error)")
            }
        }
    }
}
