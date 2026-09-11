//
//  LoginView.swift
//  DiscoScan
//

import NetworkKit
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
        .environment(AuthSession(
            oauthService: DiscogsOAuthService(
                config: DiscogsConfig(
                    consumerKey: "preview",
                    consumerSecret: "preview",
                    callbackURL: URL(string: "discoscan://oauth/callback")!,
                    userAgent: "DiscoScan/1.0",
                    callbackURLScheme: "discoscan"
                ),
                handshakeClient: PreviewNetworkClient(),
                tokenStore: PreviewTokenStore()
            ),
            apiClient: PreviewNetworkClient(),
            tokenStore: PreviewTokenStore()
        ))
}

private struct PreviewNetworkClient: NetworkManagerProtocol, Sendable {
    func request<E>(for endpoint: E) async throws -> E.Response where E: EndpointProtocol {
        throw URLError(.notConnectedToInternet)
    }

    func requestData<E>(for endpoint: E) async throws -> Data where E: EndpointProtocol {
        throw URLError(.notConnectedToInternet)
    }
}

private actor PreviewTokenStore: TokenStoreProtocol {
    func load() async throws -> OAuthTokens { throw TokenStoreError.notFound }
    func save(_ tokens: OAuthTokens) async throws {}
    func clear() async throws {}
    func currentTokens() async -> OAuthTokens? { nil }
}
