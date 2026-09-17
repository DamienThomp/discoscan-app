//
//  AuthSessionTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
@Suite(.serialized)
struct AuthSessionTests {
    private let config = DiscogsConfig(
        consumerKey: "consumer-key",
        consumerSecret: "consumer-secret",
        callbackURL: URL(string: "discoscan://oauth/callback")!,
        userAgent: "DiscoScanTests/1.0",
        callbackURLScheme: "discoscan"
    )

    @Test func initialStateIsBootstrapping() {
        let session = makeAuthSession(tokenStore: InMemoryTokenStore())
        #expect(session.state == .bootstrapping)
    }

    @Test func bootstrapWithNoTokenBecomesUnauthenticated() async {
        let session = makeAuthSession(tokenStore: InMemoryTokenStore())
        await session.bootstrap()
        #expect(session.state == .unauthenticated)
    }

    @Test func bootstrapRestoresAuthenticatedSession() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/oauth/identity")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = Data(
                """
                {"id":1,"username":"tester","resource_url":"https://api.discogs.com/users/tester","consumer_name":"DiscoScan"}
                """.utf8
            )
            return (response, data)
        }

        let session = makeAuthSession(tokenStore: tokenStore)
        await session.bootstrap()

        guard case .authenticated(let identity) = session.state else {
            Issue.record("Expected authenticated state, got \(session.state)")
            return
        }

        #expect(identity.username == "tester")
    }

    @Test func logoutClearsStoredTokens() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        let session = makeAuthSession(tokenStore: tokenStore)
        await session.logout()

        #expect(session.state == .unauthenticated)

        do {
            _ = try await tokenStore.load()
            Issue.record("Expected token store to be cleared")
        } catch TokenStoreError.notFound {
            #expect(Bool(true))
        }
    }

    private func makeAuthSession(tokenStore: InMemoryTokenStore) -> AuthSession {
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

        let storage = try! SwiftDataCacheStorage(modelContainer: TestModelContainer.make())
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
