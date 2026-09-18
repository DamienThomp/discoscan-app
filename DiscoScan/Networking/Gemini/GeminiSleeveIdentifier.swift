//
//  GeminiSleeveIdentifier.swift
//  DiscoScan
//

import Foundation
import UIKit

enum GeminiSleeveIdentifierError: LocalizedError {
    case invalidResponse
    case rateLimited
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Could not read a response from the image service."
        case .rateLimited:
            "Too many requests. Try again in a moment."
        case .httpStatus(let code):
            "Image identification failed (HTTP \(code))."
        }
    }
}

struct GeminiSleeveIdentifier: SleeveIdentifierProtocol {
    private static let prompt = """
    You identify vinyl record sleeves. Extract the artist name, album title, and catalog number \
    if visible. Return strict JSON only with keys artist, title, catalogNumber. Use null for \
    unknown fields.
    """

    private let config: GeminiConfig
    private let urlSession: URLSession

    init(config: GeminiConfig, urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }

    func identify(jpegData: Data) async throws -> SleeveIdentification {
        let preparedData = Self.downscaledJPEGData(from: jpegData) ?? jpegData
        let base64 = preparedData.base64EncodedString()

        var request = URLRequest(
            url: URL(
                string: "https://generativelanguage.googleapis.com/v1beta/models/\(config.modelName):generateContent"
            )!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try Self.makeRequestBody(base64Image: base64)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiSleeveIdentifierError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 429:
            throw GeminiSleeveIdentifierError.rateLimited
        default:
            throw GeminiSleeveIdentifierError.httpStatus(httpResponse.statusCode)
        }

        let text = try Self.extractResponseText(from: data)
        guard let jsonData = text.data(using: .utf8) else {
            throw GeminiSleeveIdentifierError.invalidResponse
        }

        return try JSONDecoder().decode(SleeveIdentification.self, from: jsonData)
    }

    private static func makeRequestBody(base64Image: String) throws -> Data {
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }

    private static func extractResponseText(from data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String, !text.isEmpty else {
            throw GeminiSleeveIdentifierError.invalidResponse
        }
        return text
    }

    private static func downscaledJPEGData(from data: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image.jpegData(compressionQuality: 0.85)
        }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return scaled.jpegData(compressionQuality: 0.85)
    }
}
