//
//  GeminiSleeveIdentifierTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct GeminiSleeveIdentifierTests {

    @Test func sleeveIdentificationBuildsSearchQuery() {
        let identification = SleeveIdentification(
            artist: "Miles Davis",
            title: "Kind of Blue",
            catalogNumber: "CL 1355"
        )

        #expect(identification.searchQuery == "Miles Davis Kind of Blue CL 1355")
        #expect(identification.isEmpty == false)
    }

    @Test func sleeveIdentificationIsEmptyWhenAllFieldsMissing() {
        let identification = SleeveIdentification(artist: nil, title: nil, catalogNumber: nil)
        #expect(identification.isEmpty)
    }

    @Test func sleeveIdentificationDecodesJSON() throws {
        let data = Data(
            """
            {"artist":"Miles Davis","title":"Kind of Blue","catalogNumber":null}
            """.utf8
        )

        let identification = try JSONDecoder().decode(SleeveIdentification.self, from: data)
        #expect(identification.artist == "Miles Davis")
        #expect(identification.title == "Kind of Blue")
        #expect(identification.catalogNumber == nil)
    }

    @Test func extractResponseTextFromGeminiPayload() throws {
        let data = Data(
            """
            {
              "candidates": [
                {
                  "content": {
                    "parts": [
                      {
                        "text": "{\\"artist\\":\\"Artist\\",\\"title\\":\\"Album\\",\\"catalogNumber\\":null}"
                      }
                    ]
                  }
                }
              ]
            }
            """.utf8
        )

        let text = try GeminiSleeveIdentifierTestSupport.extractResponseText(from: data)
        let identification = try JSONDecoder().decode(SleeveIdentification.self, from: Data(text.utf8))
        #expect(identification.artist == "Artist")
        #expect(identification.title == "Album")
    }
}

enum GeminiSleeveIdentifierTestSupport {
    static func extractResponseText(from data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String, !text.isEmpty else {
            throw GeminiSleeveIdentifierError.invalidResponse
        }
        return text
    }
}
