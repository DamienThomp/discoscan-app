//
//  KeychainGeminiCredentialsStore.swift
//  DiscoScan
//

import Foundation
import Security

actor KeychainGeminiCredentialsStore: GeminiCredentialsStoreProtocol {
    private let service: String
    private let account = "gemini-credentials"
    private var cachedCredentials: GeminiCredentials?

    init(bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "DiscoScan") {
        service = "\(bundleIdentifier).gemini"
    }

    func load() async -> GeminiCredentials? {
        if let cachedCredentials {
            return cachedCredentials
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

        guard status == errSecSuccess,
              let data = item as? Data,
              let credentials = try? JSONDecoder().decode(GeminiCredentials.self, from: data)
        else {
            return nil
        }

        cachedCredentials = credentials
        return credentials
    }

    func save(_ credentials: GeminiCredentials) async throws {
        let data = try JSONEncoder().encode(credentials)

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
            throw GeminiCredentialsStoreError.keychainError(status)
        }

        cachedCredentials = credentials
    }

    func clear() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GeminiCredentialsStoreError.keychainError(status)
        }

        cachedCredentials = nil
    }

    func resolvedConfig() async -> GeminiConfig? {
        GeminiConfig.resolve(saved: await load(), bundle: GeminiConfig.fromBundleIfPresent())
    }
}
