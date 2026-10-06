//
//  GeminiSleeveIdentifierTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
import UIKit
@testable import DiscoScan

@Suite(.serialized)
struct GeminiSleeveIdentifierTests {
    private let config = GeminiConfig(apiKey: "test-api-key", modelName: "gemini-test")

    private let successPayload = Data(
        """
        {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text": "{\\"artist\\":\\"Miles Davis\\",\\"title\\":\\"Kind of Blue\\",\\"catalogNumber\\":null}"
                  }
                ]
              }
            }
          ]
        }
        """.utf8
    )

    // MARK: - SleeveIdentification

    @Test func `Sleeve identification builds search query`() {
        let identification = SleeveIdentification(
            artist: "Miles Davis",
            title: "Kind of Blue",
            catalogNumber: "CL 1355"
        )

        #expect(identification.searchQuery == "Miles Davis Kind of Blue CL 1355")
        #expect(identification.isEmpty == false)
    }

    @Test func `Sleeve identification is empty when all fields missing`() {
        let identification = SleeveIdentification(artist: nil, title: nil, catalogNumber: nil)
        #expect(identification.isEmpty)
    }

    @Test func `Sleeve identification decodes JSON`() throws {
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

    // MARK: - Envelope and request models

    @Test func `Response envelope exposes identification JSON`() throws {
        let response = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: successPayload)
        let json = try #require(response.identificationJSON)
        let identification = try JSONDecoder().decode(SleeveIdentification.self, from: Data(json.utf8))

        #expect(identification.artist == "Miles Davis")
        #expect(identification.title == "Kind of Blue")
    }

    @Test func `Response envelope without candidates has no identification JSON`() throws {
        let response = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: Data("{}".utf8))
        #expect(response.identificationJSON == nil)
    }

    @Test func `Request encodes camelCase inline data and response schema`() throws {
        let request = GeminiGenerateContentRequest.sleeveIdentification(prompt: "Identify", base64JPEG: "AAAA")
        let data = try JSONEncoder().encode(request)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(!json.contains(":null"))

        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let contents = try #require(object["contents"] as? [[String: Any]])
        let parts = try #require(contents.first?["parts"] as? [[String: Any]])
        #expect(parts.count == 2)
        #expect(parts[0]["text"] as? String == "Identify")

        let inlineData = try #require(parts[1]["inlineData"] as? [String: Any])
        #expect(inlineData["mimeType"] as? String == "image/jpeg")
        #expect(inlineData["data"] as? String == "AAAA")

        let generationConfig = try #require(object["generationConfig"] as? [String: Any])
        #expect(generationConfig["responseMimeType"] as? String == "application/json")

        let schema = try #require(generationConfig["responseSchema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: Any])
        #expect(Set(properties.keys) == ["artist", "title", "catalogNumber"])
    }

    // MARK: - End to end

    @Test func `Identify sends generate content request and decodes result`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString.hasSuffix("/v1beta/models/gemini-test:generateContent") == true)
            #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-api-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            return Self.response(for: request, statusCode: 200, data: self.successPayload)
        } performing: {
            let result = try await makeIdentifier().identify(jpegData: Self.sampleJPEG())

            #expect(result.artist == "Miles Davis")
            #expect(result.title == "Kind of Blue")
            #expect(result.catalogNumber == nil)
        }
    }

    @Test func `Identify maps 429 to rate limited`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            Self.response(for: request, statusCode: 429, data: Data())
        } performing: {
            await #expect(throws: GeminiSleeveIdentifierError.rateLimited) {
                try await makeIdentifier().identify(jpegData: Self.sampleJPEG())
            }
        }
    }

    @Test func `Identify maps server error to HTTP status`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            Self.response(for: request, statusCode: 500, data: Data())
        } performing: {
            await #expect(throws: GeminiSleeveIdentifierError.httpStatus(500)) {
                try await makeIdentifier().identify(jpegData: Self.sampleJPEG())
            }
        }
    }

    @Test func `Identify throws invalid response when candidates are empty`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            Self.response(for: request, statusCode: 200, data: Data(#"{"candidates":[]}"#.utf8))
        } performing: {
            await #expect(throws: GeminiSleeveIdentifierError.invalidResponse) {
                try await makeIdentifier().identify(jpegData: Self.sampleJPEG())
            }
        }
    }

    // MARK: - Helpers

    private func makeIdentifier() -> GeminiSleeveIdentifier {
        let client = NetworkManagerFactory.makeDefaultClient(
            hostResolver: { _ in URL(string: "https://generativelanguage.googleapis.com")! },
            session: MockURLSessionFactory.make()
        )
        return GeminiSleeveIdentifier(config: config, client: client)
    }

    private static func response(for request: URLRequest, statusCode: Int, data: Data) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, data)
    }

    private static func sampleJPEG() -> Data {
        let size = CGSize(width: 8, height: 8)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.85) ?? Data()
    }
}
