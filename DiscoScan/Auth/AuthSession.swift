//
//  AuthSession.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

@MainActor
@Observable
final class AuthSession {
    enum State: Equatable {
        case bootstrapping
        case unauthenticated
        case authenticating
        case authenticated(DiscogsIdentity)
        case failed(String)
    }

    private(set) var state: State = .bootstrapping

    private let oauthService: DiscogsOAuthService
    private let apiClient: NetworkManagerProtocol
    private let tokenStore: TokenStoreProtocol

    init(
        oauthService: DiscogsOAuthService,
        apiClient: NetworkManagerProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.oauthService = oauthService
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    convenience init(dependencies: AppDependencies) {
        self.init(
            oauthService: dependencies.oauthService,
            apiClient: dependencies.apiClient,
            tokenStore: dependencies.tokenStore
        )
    }

    func bootstrap() async {
        guard case .bootstrapping = state else { return }

        do {
            _ = try await tokenStore.load()
            let identity = try await fetchIdentity()
            state = .authenticated(identity)
        } catch TokenStoreError.notFound {
            state = .unauthenticated
        } catch {
            try? await tokenStore.clear()
            state = .unauthenticated
        }
    }

    func login() async {
        state = .authenticating

        do {
            _ = try await oauthService.performLogin()
            let identity = try await fetchIdentity()
            state = .authenticated(identity)
        } catch {
            try? await tokenStore.clear()
            state = .failed(error.localizedDescription)
        }
    }

    func logout() async {
        try? await tokenStore.clear()
        state = .unauthenticated
    }

    func dismissError() {
        if case .failed = state {
            state = .unauthenticated
        }
    }

    private func fetchIdentity() async throws -> DiscogsIdentity {
        do {
            return try await apiClient.request(for: IdentityEndpoint())
        } catch let error as NetworkError {
            if case .serverError(let statusCode, _, _) = error, statusCode == 401 {
                try? await tokenStore.clear()
                throw error
            }
            throw error
        }
    }
}
