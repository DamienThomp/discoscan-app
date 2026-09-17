//
//  AuthSessionOfflineTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
@Suite(.serialized)
struct AuthSessionOfflineTests {
    private let config = DiscogsConfig(
        consumerKey: "consumer-key",
        consumerSecret: "consumer-secret",
        callbackURL: URL(string: "discoscan://oauth/callback")!,
        userAgent: "DiscoScanTests/1.0",
        callbackURLScheme: "discoscan"
    )

    private let identityJSON = Data(
        """
        {"id":1,"username":"tester","resource_url":"https://api.discogs.com/users/tester","consumer_name":"DiscoScan"}
        """.utf8
    )

    @Test func bootstrapOfflineWithCachedIdentityStaysAuthenticated() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        let storage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        try await storage.store(
            identityJSON,
            key: AuthSession.identityCacheKey,
            scope: .identity,
            userScope: nil,
            fetchedAt: Date()
        )

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let session = makeAuthSession(tokenStore: tokenStore, storage: storage)
        await session.bootstrap()

        guard case .authenticated(let identity) = session.state else {
            Issue.record("Expected authenticated state, got \(session.state)")
            return
        }
        #expect(identity.username == "tester")
    }

    @Test func unauthorizedClearsTokensAndCache() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        let storage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        try await storage.store(
            identityJSON,
            key: AuthSession.identityCacheKey,
            scope: .identity,
            userScope: nil,
            fetchedAt: Date()
        )

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        let session = makeAuthSession(tokenStore: tokenStore, storage: storage)
        await session.bootstrap()

        #expect(session.state == .unauthenticated)

        do {
            _ = try await tokenStore.load()
            Issue.record("Expected token store to be cleared")
        } catch TokenStoreError.notFound {
            #expect(Bool(true))
        }

        let cachedEntry = try await storage.entry(for: CachePolicy.namespacedKey(AuthSession.identityCacheKey, userScope: nil))
        #expect(cachedEntry == nil)
    }

    @Test func logoutClearsCache() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        let storage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        try await storage.store(
            identityJSON,
            key: AuthSession.identityCacheKey,
            scope: .identity,
            userScope: nil,
            fetchedAt: Date()
        )

        let session = makeAuthSession(tokenStore: tokenStore, storage: storage)
        await session.logout()

        let cachedEntry = try await storage.entry(for: CachePolicy.namespacedKey(AuthSession.identityCacheKey, userScope: nil))
        #expect(cachedEntry == nil)
    }

    private func makeAuthSession(
        tokenStore: InMemoryTokenStore,
        storage: SwiftDataCacheStorage
    ) -> AuthSession {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let rateLimitTracker = RateLimitTracker()
        let handshakeClient = NetworkManagerFactory.makeDefaultClient(
            hostResolver: { _ in URL(string: "https://api.discogs.com")! },
            customInterceptors: [UserAgentInterceptor(userAgent: config.userAgent)],
            session: MockURLSessionFactory.make()
        )

        let apiClient = NetworkManagerFactory.makeDefaultClient(
            hostResolver: { _ in URL(string: "https://api.discogs.com")! },
            customInterceptors: [
                UserAgentInterceptor(userAgent: config.userAgent),
                DiscogsOAuthInterceptor(config: config, tokenStore: tokenStore),
                DiscogsRateLimitInterceptor(tracker: rateLimitTracker)
            ],
            session: MockURLSessionFactory.make(),
            decoder: decoder
        )

        let oauthService = DiscogsOAuthService(
            config: config,
            handshakeClient: handshakeClient,
            tokenStore: tokenStore,
            webAuthPresenter: WebAuthPresenter()
        )

        let cachedFetcher = CachedFetcher(
            apiClient: apiClient,
            storage: storage,
            rateLimitTracker: rateLimitTracker,
            decoder: decoder
        )

        return AuthSession(
            oauthService: oauthService,
            cachedFetcher: cachedFetcher,
            cacheStorage: storage,
            tokenStore: tokenStore
        )
    }
}
