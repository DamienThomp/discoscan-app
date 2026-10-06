//
//  GeminiGenerateContentResponse.swift
//  DiscoScan
//

import Foundation

nonisolated struct GeminiGenerateContentResponse: Decodable, Sendable, Equatable {
    let candidates: [Candidate]

    nonisolated struct Candidate: Decodable, Sendable, Equatable {
        let content: Content
    }

    nonisolated struct Content: Decodable, Sendable, Equatable {
        let parts: [Part]
    }

    nonisolated struct Part: Decodable, Sendable, Equatable {
        let text: String?
    }

    /// Gemini returns the structured result as a JSON string inside the first text part.
    var identificationJSON: String? {
        guard let text = candidates.first?.content.parts.first?.text, !text.isEmpty else {
            return nil
        }
        return text
    }

    init(candidates: [Candidate]) {
        self.candidates = candidates
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        candidates = try container.decodeIfPresent([Candidate].self, forKey: .candidates) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case candidates
    }
}
