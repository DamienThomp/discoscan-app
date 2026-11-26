//
//  GeminiGetModelEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct GeminiGetModelEndpoint: EndpointProtocol {
    typealias Response = GeminiModel

    let config: GeminiConfig

    var path: String { "v1beta/models/\(config.modelName)" }
    var httpMethod: HTTPMethod { .get }
    var headers: [String: String]? { ["x-goog-api-key": config.apiKey] }
}
