//
//  DiscogsRateLimitInterceptor.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct DiscogsRateLimitInterceptor: RequestInterceptor {
    let tracker: RateLimitTracker

    func adapt(_ request: inout URLRequest) async throws {}

    func didReceive(_ response: HTTPURLResponse, data: Data, for request: URLRequest) async {
        guard
            let remaining = Self.headerInt(from: response, named: "X-Discogs-Ratelimit-Remaining"),
            let limit = Self.headerInt(from: response, named: "X-Discogs-Ratelimit")
        else {
            return
        }

        await tracker.record(remaining: remaining, limit: limit, at: Date())
    }

    private static func headerInt(from response: HTTPURLResponse, named name: String) -> Int? {
        for (key, value) in response.allHeaderFields {
            guard
                let key = key as? String,
                key.caseInsensitiveCompare(name) == .orderedSame,
                let stringValue = value as? String
            else {
                continue
            }
            return Int(stringValue)
        }
        return nil
    }
}
