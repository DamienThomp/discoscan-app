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

private let unimplementedGeminiCredentialsStore = UnimplementedGeminiCredentialsStore()

extension EnvironmentValues {
    @Entry var geminiCredentialsStore: any GeminiCredentialsStoreProtocol = unimplementedGeminiCredentialsStore
}
