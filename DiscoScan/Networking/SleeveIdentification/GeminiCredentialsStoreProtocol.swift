//
//  GeminiCredentialsStoreProtocol.swift
//  DiscoScan
//

import Foundation

nonisolated struct GeminiCredentials: Codable, Sendable, Equatable {
    var apiKey: String
    var modelName: String
}

nonisolated enum GeminiCredentialsStoreError: Error, LocalizedError {
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            "Keychain error (\(status))."
        }
    }
}

nonisolated protocol GeminiCredentialsStoreProtocol: Sendable {
    func load() async -> GeminiCredentials?
    func save(_ credentials: GeminiCredentials) async throws
    func clear() async throws
    func resolvedConfig() async -> GeminiConfig?
}
