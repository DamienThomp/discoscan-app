//
//  InMemoryTokenStore.swift
//  DiscoScanTests
//

@testable import DiscoScan

actor InMemoryTokenStore: TokenStoreProtocol {
    private var tokens: OAuthTokens?

    func load() async throws -> OAuthTokens {
        guard let tokens else {
            throw TokenStoreError.notFound
        }
        return tokens
    }

    func save(_ tokens: OAuthTokens) async throws {
        self.tokens = tokens
    }

    func clear() async throws {
        tokens = nil
    }

    func currentTokens() async -> OAuthTokens? {
        tokens
    }
}
