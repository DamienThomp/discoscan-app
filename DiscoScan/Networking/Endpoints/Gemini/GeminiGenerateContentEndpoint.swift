//
//  GeminiGenerateContentEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct GeminiGenerateContentEndpoint: EndpointProtocol {
    typealias Response = GeminiGenerateContentResponse

    let config: GeminiConfig
    let requestBody: GeminiGenerateContentRequest

    var path: String { "v1beta/models/\(config.modelName):generateContent" }
    var httpMethod: HTTPMethod { .post }
    var headers: [String: String]? { ["x-goog-api-key": config.apiKey] }
    var body: (any Encodable & Sendable)? { requestBody }
}
