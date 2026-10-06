//
//  GeminiSleeveIdentifier.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import UIKit

struct GeminiSleeveIdentifier: SleeveIdentifierProtocol {
    static let prompt = """
    You identify vinyl record sleeves. Extract the artist name, album title, and catalog number \
    if visible. Use null for unknown fields.
    """

    private let config: GeminiConfig
    private let client: any NetworkManagerProtocol

    init(config: GeminiConfig, client: any NetworkManagerProtocol) {
        self.config = config
        self.client = client
    }

    func identify(jpegData: Data) async throws -> SleeveIdentification {
        let preparedData = Self.downscaledJPEGData(from: jpegData) ?? jpegData
        let endpoint = GeminiGenerateContentEndpoint(
            config: config,
            requestBody: .sleeveIdentification(
                prompt: Self.prompt,
                base64JPEG: preparedData.base64EncodedString()
            )
        )

        let response: GeminiGenerateContentResponse
        do {
            response = try await client.request(for: endpoint)
        } catch NetworkError.taskCancelled {
            throw CancellationError()
        } catch let error as NetworkError {
            throw Self.mapNetworkError(error)
        }

        return try Self.decodeIdentification(from: response)
    }

    private static func mapNetworkError(_ error: NetworkError) -> SleeveIdentificationError {
        switch error {
        case .taskCancelled:
            .serviceUnavailable
        case .serverError(let statusCode, _, _):
            if statusCode == 429 {
                .rateLimited
            } else if [400, 401, 403, 404].contains(statusCode) {
                .notConfigured
            } else {
                .serviceUnavailable
            }
        case .unauthorized:
            .notConfigured
        case .transportError:
            .offline
        case .decodingError, .emptyResponse, .invalidUrl, .encodingError:
            .unreadableResponse
        }
    }

    private static func decodeIdentification(
        from response: GeminiGenerateContentResponse
    ) throws -> SleeveIdentification {
        guard let jsonData = response.identificationJSON?.data(using: .utf8) else {
            throw SleeveIdentificationError.unreadableResponse
        }

        do {
            return try JSONDecoder().decode(SleeveIdentification.self, from: jsonData)
        } catch {
            throw SleeveIdentificationError.unreadableResponse
        }
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
