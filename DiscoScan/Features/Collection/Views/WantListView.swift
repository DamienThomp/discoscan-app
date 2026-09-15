//
//  WantListView.swift
//  DiscoScan
//

import NetworkKit
import SwiftData
import SwiftUI

struct WantListView: View {

    @Environment(AuthSession.self) private var authSession
    @Environment(\.cachedFetcher) private var cacheFetcher

    var body: some View {
        LoadingContainerView(loadingAction: fetchWantList) { list in
            if list.wants.isEmpty {
                ContentUnavailableView(
                    "Want List",
                    systemImage: "heart",
                    description: Text("Your want list is empty.")
                )
            } else {
                List(list.wants) { item in
                    Text(item.basicInformation.title)
                }
            }
        }
    }
}


extension WantListView {

    @Sendable
    private func fetchWantList() async throws -> WantListResponse {
        guard case .authenticated(let identity) = authSession.state else {
            throw AuthSessionError.notAuthenticated
        }
        let endpoint = WantListEndpoint(username: identity.username)
        return try await cacheFetcher.fetch(
            endpoint,
            key: "wants",
            scope: .wantlist,
            userScope: identity.username,
            forceRefresh: false
        )
    }
}

#Preview {
    NavigationStack {
        WantListView()
            .environment(previewWantListAuthSession())
            .environment(\.cachedFetcher, PreviewEmptyWantListCachedFetcher())
    }
}

#if DEBUG
@MainActor
private func previewWantListAuthSession() -> AuthSession {
    let config = DiscogsConfig(
        consumerKey: "preview",
        consumerSecret: "preview",
        callbackURL: URL(string: "discoscan://oauth/callback")!,
        userAgent: "DiscoScan/1.0",
        callbackURLScheme: "discoscan"
    )
    let session = AuthSession(
        oauthService: DiscogsOAuthService(
            config: config,
            handshakeClient: PreviewUnimplementedNetworkClient(),
            tokenStore: PreviewUnimplementedTokenStore()
        ),
        cachedFetcher: PreviewEmptyWantListCachedFetcher(),
        cacheStorage: SwiftDataCacheStorage(modelContainer: try! ModelContainer(
            for: CachedRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )),
        tokenStore: PreviewUnimplementedTokenStore()
    )
    session.setPreviewState(.authenticated(DiscogsIdentity(
        id: 1,
        username: "preview",
        resourceURL: nil,
        consumerName: nil
    )))
    return session
}

private actor PreviewEmptyWantListCachedFetcher: CachedFetcherProtocol {
    private static let emptyResponse = WantListResponse(
        pagination: SearchPagination(page: 1, pages: 1, perPage: 50, items: 0),
        wants: []
    )

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        guard let response = Self.emptyResponse as? E.Response else {
            preconditionFailure("Unexpected preview endpoint response type: \(E.Response.self)")
        }
        return response
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        nil
    }
}

private struct PreviewUnimplementedNetworkClient: NetworkManagerProtocol, Sendable {
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

private actor PreviewUnimplementedTokenStore: TokenStoreProtocol {
    func load() async throws -> OAuthTokens { throw TokenStoreError.notFound }
    func save(_ tokens: OAuthTokens) async throws {}
    func clear() async throws {}
    func currentTokens() async -> OAuthTokens? { nil }
}
#endif
