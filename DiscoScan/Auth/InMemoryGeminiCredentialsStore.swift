//
//  InMemoryGeminiCredentialsStore.swift
//  DiscoScan
//

import Foundation

actor InMemoryGeminiCredentialsStore: GeminiCredentialsStoreProtocol {
    private var saved: GeminiCredentials?
    private var bundleConfig: GeminiConfig?

    init(saved: GeminiCredentials? = nil, bundleConfig: GeminiConfig? = nil) {
        self.saved = saved
        self.bundleConfig = bundleConfig
    }

    func load() async -> GeminiCredentials? {
        saved
    }

    func save(_ credentials: GeminiCredentials) async throws {
        saved = credentials
    }

    func clear() async throws {
        saved = nil
    }

    func resolvedConfig() async -> GeminiConfig? {
        GeminiConfig.resolve(saved: saved, bundle: bundleConfig)
    }
}
