//
//  GeminiGenerateContentRequest.swift
//  DiscoScan
//

import Foundation

nonisolated struct GeminiGenerateContentRequest: Encodable, Sendable, Equatable {
    let contents: [Content]
    let generationConfig: GenerationConfig

    nonisolated struct Content: Encodable, Sendable, Equatable {
        let parts: [Part]
    }

    nonisolated struct Part: Encodable, Sendable, Equatable {
        var text: String?
        var inlineData: InlineData?
    }

    nonisolated struct InlineData: Encodable, Sendable, Equatable {
        let mimeType: String
        let data: String
    }

    nonisolated struct GenerationConfig: Encodable, Sendable, Equatable {
        let responseMimeType: String
        let responseSchema: Schema?
    }

    nonisolated struct Schema: Encodable, Sendable, Equatable {
        let type: String
        var nullable: Bool?
        var properties: [String: Schema]?

        static let nullableString = Schema(type: "STRING", nullable: true)
    }

    static func sleeveIdentification(prompt: String, base64JPEG: String) -> GeminiGenerateContentRequest {
        GeminiGenerateContentRequest(
            contents: [
                Content(parts: [
                    Part(text: prompt),
                    Part(inlineData: InlineData(mimeType: "image/jpeg", data: base64JPEG))
                ])
            ],
            generationConfig: GenerationConfig(
                responseMimeType: "application/json",
                responseSchema: Schema(
                    type: "OBJECT",
                    properties: [
                        "artist": .nullableString,
                        "title": .nullableString,
                        "catalogNumber": .nullableString
                    ]
                )
            )
        )
    }
}
