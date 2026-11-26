//
//  GeminiConfig.swift
//  DiscoScan
//

import Foundation

nonisolated struct GeminiConfig: Sendable, Equatable {
    let apiKey: String
    let modelName: String

    static func fromBundleIfPresent(bundle: Bundle = .main) -> GeminiConfig? {
        guard
            let apiKey = trimmed(bundle.object(forInfoDictionaryKey: "GEMINIApiKey") as? String),
            let modelName = trimmed(bundle.object(forInfoDictionaryKey: "GEMINIModel") as? String)
        else {
            return nil
        }

        return GeminiConfig(apiKey: apiKey, modelName: modelName)
    }

    static func resolve(saved: GeminiCredentials?, bundle: GeminiConfig?) -> GeminiConfig? {
        if let apiKey = trimmed(saved?.apiKey) {
            let modelName = trimmed(saved?.modelName) ?? bundle?.modelName ?? SleeveIdentificationEngine.defaultModelName
            return GeminiConfig(apiKey: apiKey, modelName: modelName)
        }

        return bundle
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
