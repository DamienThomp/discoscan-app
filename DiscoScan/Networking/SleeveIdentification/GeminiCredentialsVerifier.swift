//
//  GeminiCredentialsVerifier.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated enum GeminiCredentialsVerification: Sendable, Equatable {
    case valid
    case validQuotaExceeded
    case invalidKey
    case unknownModel
    case rejected
    case offline
    case unavailable

    var shouldSave: Bool {
        switch self {
        case .valid, .validQuotaExceeded:
            true
        case .invalidKey, .unknownModel, .rejected, .offline, .unavailable:
            false
        }
    }

    var message: String? {
        switch self {
        case .valid:
            nil
        case .validQuotaExceeded:
            "The key and model were saved. The Gemini quota is used up."
        case .invalidKey:
            "That API key was rejected."
        case .unknownModel:
            "That model name wasn't found."
        case .rejected:
            "Gemini rejected that key or model."
        case .offline:
            "You appear to be offline. The key was not saved."
        case .unavailable:
            "Gemini could not be reached. The key was not saved."
        }
    }
}

nonisolated protocol GeminiCredentialsVerifying: Sendable {
    func verify(_ config: GeminiConfig) async throws -> GeminiCredentialsVerification
}

nonisolated struct GeminiCredentialsVerifier: GeminiCredentialsVerifying {
    private let client: any NetworkManagerProtocol

    init(client: any NetworkManagerProtocol) {
        self.client = client
    }

    func verify(_ config: GeminiConfig) async throws -> GeminiCredentialsVerification {
        do {
            _ = try await client.request(for: GeminiGetModelEndpoint(config: config))
            try Task.checkCancellation()
            return .valid
        } catch is CancellationError {
            throw CancellationError()
        } catch NetworkError.taskCancelled {
            throw CancellationError()
        } catch let error as NetworkError {
            return Self.verification(for: error)
        } catch {
            return .unavailable
        }
    }

    private static func verification(for error: NetworkError) -> GeminiCredentialsVerification {
        switch error {
        case .taskCancelled:
            .unavailable
        case .serverError(let statusCode, _, _):
            switch statusCode {
            case 401, 403:
                .invalidKey
            case 404:
                .unknownModel
            case 400:
                .rejected
            case 429:
                .validQuotaExceeded
            default:
                .unavailable
            }
        case .transportError:
            .offline
        case .unauthorized:
            .invalidKey
        case .invalidUrl, .emptyResponse, .decodingError, .encodingError:
            .unavailable
        }
    }
}
