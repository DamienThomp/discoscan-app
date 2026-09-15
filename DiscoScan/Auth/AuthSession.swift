//
//  AuthSession.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

enum AuthSessionError: Error {
    case notAuthenticated
}

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

    static let identityCacheKey = "identity"

    private(set) var state: State = .bootstrapping

    private let oauthService: DiscogsOAuthService
    private let cachedFetcher: any CachedFetcherProtocol
    private let cacheStorage: SwiftDataCacheStorage
    private let tokenStore: TokenStoreProtocol

    init(
        oauthService: DiscogsOAuthService,
        cachedFetcher: any CachedFetcherProtocol,
        cacheStorage: SwiftDataCacheStorage,
        tokenStore: TokenStoreProtocol
    ) {
        self.oauthService = oauthService
        self.cachedFetcher = cachedFetcher
        self.cacheStorage = cacheStorage
        self.tokenStore = tokenStore
    }

    convenience init(dependencies: AppDependencies) {
        self.init(
            oauthService: dependencies.oauthService,
            cachedFetcher: dependencies.cachedFetcher,
            cacheStorage: dependencies.cacheStorage,
            tokenStore: dependencies.tokenStore
        )
    }

    func bootstrap() async {
        guard case .bootstrapping = state else { return }

        do {
            _ = try await tokenStore.load()

            if let cached = try? await cachedFetcher.cachedValue(
                IdentityEndpoint(),
                key: Self.identityCacheKey,
                userScope: nil
            ) {
                state = .authenticated(cached)
            }

            let identity = try await fetchIdentity()
            state = .authenticated(identity)
        } catch TokenStoreError.notFound {
            state = .unauthenticated
        } catch let error as NetworkError {
            if case .serverError(let statusCode, _, _) = error, statusCode == 401 {
                state = .unauthenticated
                return
            }
            if case .authenticated = state {
                return
            }
            try? await tokenStore.clear()
            state = .unauthenticated
        } catch {
            if case .authenticated = state {
                return
            }
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
        try? await cacheStorage.clear(userScope: nil)
        state = .unauthenticated
    }

    func dismissError() {
        if case .failed = state {
            state = .unauthenticated
        }
    }

    #if DEBUG
    func setPreviewState(_ previewState: State) {
        state = previewState
    }
    #endif

    private func fetchIdentity() async throws -> DiscogsIdentity {
        do {
            return try await cachedFetcher.fetch(
                IdentityEndpoint(),
                key: Self.identityCacheKey,
                scope: .identity,
                userScope: nil,
                forceRefresh: true
            )
        } catch let error as NetworkError {
            if case .serverError(let statusCode, _, _) = error, statusCode == 401 {
                try? await tokenStore.clear()
                try? await cacheStorage.clear(userScope: nil)
                throw error
            }
            throw error
        }
    }
}
