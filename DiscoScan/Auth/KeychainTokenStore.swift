//
//  KeychainTokenStore.swift
//  DiscoScan
//

import Foundation
import Security

actor KeychainTokenStore: TokenStoreProtocol {
    private let service = "com.Damien-Thompson.DiscoScan.oauth"
    private let account = "discogs-oauth"
    private var cachedTokens: OAuthTokens?

    func load() async throws -> OAuthTokens {
        if let cachedTokens {
            return cachedTokens
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw TokenStoreError.notFound
        }

        guard status == errSecSuccess else {
            throw TokenStoreError.keychainError(status)
        }

        guard
            let data = item as? Data,
            let tokens = try? JSONDecoder().decode(OAuthTokens.self, from: data)
        else {
            throw TokenStoreError.notFound
        }

        cachedTokens = tokens
        return tokens
    }

    func save(_ tokens: OAuthTokens) async throws {
        let data = try JSONEncoder().encode(tokens)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStoreError.keychainError(status)
        }

        cachedTokens = tokens
    }

    func clear() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.keychainError(status)
        }

        cachedTokens = nil
    }

    func currentTokens() async -> OAuthTokens? {
        if let cachedTokens {
            return cachedTokens
        }

        return try? await load()
    }
}
