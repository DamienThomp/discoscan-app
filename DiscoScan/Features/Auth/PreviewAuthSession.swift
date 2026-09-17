//
//  PreviewAuthSession.swift
//  DiscoScan
//

#if DEBUG
import Foundation
import NetworkKit
import SwiftData

@MainActor
func previewAuthSession() -> AuthSession {
    let config = DiscogsConfig(
        consumerKey: "preview",
        consumerSecret: "preview",
        callbackURL: URL(string: "discoscan://oauth/callback")!,
        userAgent: "DiscoScan/1.0",
        callbackURLScheme: "discoscan"
    )
    let tokenStore = PreviewTokenStore()
    let handshakeClient = PreviewNetworkClient()
    let oauthService = DiscogsOAuthService(
        config: config,
        handshakeClient: handshakeClient,
        tokenStore: tokenStore,
        webAuthPresenter: WebAuthPresenter()
    )
    let container = try! ModelContainer(
        for: CachedRecord.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let storage = SwiftDataCacheStorage(modelContainer: container)
    let cachedFetcher = CachedFetcher(
        apiClient: PreviewNetworkClient(),
        storage: storage,
        rateLimitTracker: RateLimitTracker(),
        decoder: JSONDecoder()
    )
    return AuthSession(
        oauthService: oauthService,
        cachedFetcher: cachedFetcher,
        cacheStorage: storage,
        tokenStore: tokenStore
    )
}

@MainActor
func previewAuthenticatedAuthSession() -> AuthSession {
    let session = previewAuthSession()
    session.setPreviewState(.authenticated(PreviewAuthFixtures.identity))
    return session
}

private enum PreviewAuthFixtures {
    static let identity = DiscogsIdentity(
        id: 1,
        username: "preview",
        resourceURL: nil,
        consumerName: nil
    )
}

private struct PreviewNetworkClient: NetworkManagerProtocol, Sendable {
    func request<E>(for endpoint: E) async throws -> E.Response where E: EndpointProtocol {
        throw URLError(.notConnectedToInternet)
    }

    func requestData<E>(for endpoint: E) async throws -> Data where E: EndpointProtocol {
        throw URLError(.notConnectedToInternet)
    }

    func response<E>(for endpoint: E) async throws -> NetworkResponse<E.Response> where E: EndpointProtocol {
        throw URLError(.notConnectedToInternet)
    }

    func responseData<E>(for endpoint: E) async throws -> NetworkResponse<Data> where E: EndpointProtocol {
        throw URLError(.notConnectedToInternet)
    }
}

private actor PreviewTokenStore: TokenStoreProtocol {
    func load() async throws -> OAuthTokens { throw TokenStoreError.notFound }
    func save(_ tokens: OAuthTokens) async throws {}
    func clear() async throws {}
    func currentTokens() async -> OAuthTokens? { nil }
}
#endif
