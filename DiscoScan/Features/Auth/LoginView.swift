//
//  LoginView.swift
//  DiscoScan
//

import NetworkKit
import SwiftData
import SwiftUI

struct LoginView: View {
    @Environment(AuthSession.self) private var authSession
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "opticaldisc.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("DiscoScan")
                .font(.largeTitle.bold())

            Text("Connect your Discogs account to search releases and manage your collection.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Connect with Discogs") {
                Task {
                    await authSession.login()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: authSession.state) { _, newValue in
            if case .failed = newValue {
                showErrorAlert = true
            }
        }
        .alert("Sign In Failed", isPresented: $showErrorAlert) {
            Button("OK") {
                authSession.dismissError()
            }
        } message: {
            if case .failed(let message) = authSession.state {
                Text(message)
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(previewAuthSession())
}

@MainActor
private func previewAuthSession() -> AuthSession {
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
        tokenStore: tokenStore
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
