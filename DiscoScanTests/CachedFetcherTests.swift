//
//  CachedFetcherTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@Suite(.serialized)
struct CachedFetcherTests {
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

    @Test func freshCacheHitSkipsNetwork() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            #expect(request.url?.path == "/oauth/identity")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, now: { Date(timeIntervalSince1970: 1_000) })
        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )

        requestCount = 0
        let cached = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )

        #expect(cached.username == "tester")
        #expect(requestCount == 0)
    }

    @Test func expiredCacheRefetches() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let storage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        let baseDate = Date(timeIntervalSince1970: 1_000)
        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, storage: storage, now: { baseDate })

        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )
        #expect(requestCount == 1)

        requestCount = 0
        let expiredFetcher = try makeCachedFetcher(
            tokenStore: tokenStore,
            storage: storage,
            now: { baseDate.addingTimeInterval(CacheScope.identity.ttl + 1) }
        )
        _ = try await expiredFetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )
        #expect(requestCount == 1)
    }

    @Test func forceRefreshBypassesFreshCache() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, now: { Date(timeIntervalSince1970: 1_000) })
        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )
        #expect(requestCount == 1)

        requestCount = 0
        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: true
        )
        #expect(requestCount == 1)
    }

    @Test func concurrentRequestsAreDeduped() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            Thread.sleep(forTimeInterval: 0.05)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, now: { Date(timeIntervalSince1970: 2_000) })

        async let first = fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: true
        )
        async let second = fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: true
        )

        _ = try await (first, second)
        #expect(requestCount == 1)
    }

    @Test func offlineReturnsStaleCache() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, now: { Date(timeIntervalSince1970: 3_000) })
        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let identity = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: true
        )
        #expect(identity.username == "tester")
    }

    @Test func invalidateRemovesCachedEntry() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let storage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, storage: storage, now: { Date(timeIntervalSince1970: 5_000) })

        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )
        #expect(requestCount == 1)

        await fetcher.invalidate(key: "identity")
        #expect(try await storage.entry(for: "identity") == nil)

        requestCount = 0
        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )
        #expect(requestCount == 1)
    }

    @Test func invalidateKeysMatchingPrefixRemovesOnlyMatchingEntries() async throws {
        let storage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        let fetchedAt = Date(timeIntervalSince1970: 6_000)

        try await storage.store(Data("page1".utf8), key: "collectionFolder-1-page-1", scope: .collection, fetchedAt: fetchedAt)
        try await storage.store(Data("page2".utf8), key: "collectionFolder-1-page-2", scope: .collection, fetchedAt: fetchedAt)
        try await storage.store(Data("other".utf8), key: "collectionFolders", scope: .collection, fetchedAt: fetchedAt)

        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))
        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, storage: storage, now: { fetchedAt })

        await fetcher.invalidateKeys(matchingPrefix: "collectionFolder-1-page-")

        #expect(try await storage.entry(for: "collectionFolder-1-page-1") == nil)
        #expect(try await storage.entry(for: "collectionFolder-1-page-2") == nil)
        #expect(try await storage.entry(for: "collectionFolders") != nil)
    }

    @Test func rateLimit429FallsBackToStaleCache() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.save(OAuthTokens(token: "access-token", tokenSecret: "access-secret"))

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "application/json",
                    "X-Discogs-Ratelimit-Remaining": "59",
                    "X-Discogs-Ratelimit": "60"
                ]
            )!
            return (response, self.identityJSON)
        }

        let fetcher = try makeCachedFetcher(tokenStore: tokenStore, now: { Date(timeIntervalSince1970: 4_000) })
        _ = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: false
        )

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        let identity = try await fetcher.fetch(
            IdentityEndpoint(),
            key: "identity",
            scope: .identity,
            forceRefresh: true
        )
        #expect(identity.username == "tester")
    }

    private func makeCachedFetcher(
        tokenStore: InMemoryTokenStore,
        storage: SwiftDataCacheStorage? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) throws -> CachedFetcher {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let rateLimitTracker = RateLimitTracker()
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

        let resolvedStorage: SwiftDataCacheStorage
        if let storage {
            resolvedStorage = storage
        } else {
            resolvedStorage = SwiftDataCacheStorage(modelContainer: try TestModelContainer.make())
        }

        return CachedFetcher(
            apiClient: apiClient,
            storage: resolvedStorage,
            rateLimitTracker: rateLimitTracker,
            decoder: decoder,
            now: now
        )
    }
}
