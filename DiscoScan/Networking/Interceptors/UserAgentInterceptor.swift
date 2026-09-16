//
//  UserAgentInterceptor.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct UserAgentInterceptor: RequestInterceptor {
    let userAgent: String

    func adapt(_ request: inout URLRequest) async throws {
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }
}
