//
//  GeminiConfig.swift
//  DiscoScan
//

import Foundation

nonisolated struct GeminiConfig: Sendable {
    let apiKey: String
    let modelName: String

    static func fromBundle() -> GeminiConfig {
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINIApiKey") as? String,
            !apiKey.isEmpty,
            let modelName = Bundle.main.object(forInfoDictionaryKey: "GEMINIModel") as? String,
            !modelName.isEmpty
        else {
            fatalError(
                """
                Missing Gemini configuration. Copy Configuration/Secrets.xcconfig.example to \
                Configuration/Secrets.xcconfig and set GEMINI_API_KEY and GEMINI_MODEL.
                """
            )
        }

        return GeminiConfig(apiKey: apiKey, modelName: modelName)
    }
}
