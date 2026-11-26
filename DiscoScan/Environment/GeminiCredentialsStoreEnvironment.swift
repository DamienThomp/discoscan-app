//
//  GeminiCredentialsStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

private struct UnimplementedGeminiCredentialsStore: GeminiCredentialsStoreProtocol {
    func load() async -> GeminiCredentials? {
        fatalError("geminiCredentialsStore environment value was not injected.")
    }

    func save(_ credentials: GeminiCredentials) async throws {
        fatalError("geminiCredentialsStore environment value was not injected.")
    }

    func clear() async throws {
        fatalError("geminiCredentialsStore environment value was not injected.")
    }

    func resolvedConfig() async -> GeminiConfig? {
        fatalError("geminiCredentialsStore environment value was not injected.")
    }
}

private struct UnimplementedGeminiCredentialsVerifier: GeminiCredentialsVerifying {
    func verify(_ config: GeminiConfig) async throws -> GeminiCredentialsVerification {
        fatalError("geminiCredentialsVerifier environment value was not injected.")
    }
}

private let unimplementedGeminiCredentialsStore = UnimplementedGeminiCredentialsStore()
private let unimplementedGeminiCredentialsVerifier = UnimplementedGeminiCredentialsVerifier()

extension EnvironmentValues {
    @Entry var geminiCredentialsStore: any GeminiCredentialsStoreProtocol = unimplementedGeminiCredentialsStore
    @Entry var geminiCredentialsVerifier: any GeminiCredentialsVerifying = unimplementedGeminiCredentialsVerifier
}

#if DEBUG
struct PreviewGeminiCredentialsVerifier: GeminiCredentialsVerifying {
    func verify(_ config: GeminiConfig) async throws -> GeminiCredentialsVerification {
        .valid
    }
}
#endif
