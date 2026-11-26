//
//  GeminiCredentialsVerifierTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

struct GeminiCredentialsVerifierTests {
    private let config = GeminiConfig(apiKey: "test-api-key", modelName: "gemini-test")

    private let modelPayload = Data(
        """
        {"name":"models/gemini-test","displayName":"Gemini Test"}
        """.utf8
    )

    @Test func `Valid model response accepts the key`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.absoluteString.hasSuffix("/v1beta/models/gemini-test") == true)
            #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-api-key")
            return Self.response(for: request, statusCode: 200, data: modelPayload)
        } performing: {
            let result = try await makeVerifier().verify(config)
            #expect(result == .valid)
        }
    }

    @Test func `Unauthorized response rejects the key`() async throws {
        try await expect(.invalidKey, statusCode: 401)
        try await expect(.invalidKey, statusCode: 403)
    }

    @Test func `Missing model response rejects the model name`() async throws {
        try await expect(.unknownModel, statusCode: 404)
    }

    @Test func `Bad request rejects the credentials`() async throws {
        try await expect(.rejected, statusCode: 400)
    }

    @Test func `Rate limit still accepts the credentials`() async throws {
        try await expect(.validQuotaExceeded, statusCode: 429)
    }

    @Test func `Offline response does not accept the credentials`() async throws {
        _ = try await MockURLProtocol.withLockedHandler { _ in
            throw URLError(.notConnectedToInternet)
        } performing: {
            let result = try await makeVerifier().verify(config)
            #expect(result == .offline)
        }
    }

    @Test func `Server failure is unavailable`() async throws {
        try await expect(.unavailable, statusCode: 503)
    }

    @Test func `Undecodable success is unavailable`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            Self.response(for: request, statusCode: 200, data: Data("[]".utf8))
        } performing: {
            let result = try await makeVerifier().verify(config)
            #expect(result == .unavailable)
        }
    }

    @Test func `Model name with a space is encoded in the path`() async throws {
        try await MockURLProtocol.withLockedHandler { request in
            #expect(request.url?.absoluteString.contains("/v1beta/models/gemini%20test") == true)
            return Self.response(for: request, statusCode: 200, data: modelPayload)
        } performing: {
            let result = try await makeVerifier().verify(
                GeminiConfig(apiKey: "test-api-key", modelName: "gemini test")
            )
            #expect(result == .valid)
        }
    }

    @Test func `Only accepted results can be saved`() {
        #expect(GeminiCredentialsVerification.valid.shouldSave)
        #expect(GeminiCredentialsVerification.validQuotaExceeded.shouldSave)
        #expect(!GeminiCredentialsVerification.invalidKey.shouldSave)
        #expect(!GeminiCredentialsVerification.unknownModel.shouldSave)
        #expect(!GeminiCredentialsVerification.rejected.shouldSave)
        #expect(!GeminiCredentialsVerification.offline.shouldSave)
        #expect(!GeminiCredentialsVerification.unavailable.shouldSave)
    }

    private func expect(
        _ verification: GeminiCredentialsVerification,
        statusCode: Int
    ) async throws {
        try await MockURLProtocol.withLockedHandler { request in
            Self.response(for: request, statusCode: statusCode, data: Data())
        } performing: {
            let result = try await makeVerifier().verify(config)
            #expect(result == verification)
        }
    }

    private func makeVerifier() -> GeminiCredentialsVerifier {
        let client = NetworkManagerFactory.makeDefaultClient(
            hostResolver: { _ in URL(string: "https://generativelanguage.googleapis.com")! },
            session: MockURLSessionFactory.make()
        )
        return GeminiCredentialsVerifier(client: client)
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
}
