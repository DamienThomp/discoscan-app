//
//  OAuthTokens.swift
//  DiscoScan
//

import Foundation

nonisolated struct OAuthTokens: Codable, Sendable, Equatable {
    let token: String
    let tokenSecret: String
}

nonisolated struct OAuthRequestTokens: Sendable, Equatable {
    let token: String
    let tokenSecret: String
}

enum TokenStoreError: Error, LocalizedError {
    case notFound
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "No stored OAuth tokens were found."
        case .keychainError(let status):
            return "Keychain error (\(status))."
        }
    }
}

protocol TokenStoreProtocol: Sendable {
    func load() async throws -> OAuthTokens
    func save(_ tokens: OAuthTokens) async throws
    func clear() async throws
    func currentTokens() async -> OAuthTokens?
}
