//
//  DiscogsRateLimitInterceptorTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct DiscogsRateLimitInterceptorTests {
    @Test func recordsRateLimitHeaders() async {
        let tracker = RateLimitTracker()
        let interceptor = DiscogsRateLimitInterceptor(tracker: tracker)

        let url = URL(string: "https://api.discogs.com/database/search")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "X-Discogs-Ratelimit-Remaining": "12",
                "X-Discogs-Ratelimit": "60"
            ]
        )!

        await interceptor.didReceive(response, data: Data(), for: URLRequest(url: url))

        let shouldThrottle = await tracker.shouldThrottle(now: Date())
        #expect(shouldThrottle == false)
    }

    @Test func parsesHeadersCaseInsensitively() async {
        let tracker = RateLimitTracker()
        let interceptor = DiscogsRateLimitInterceptor(tracker: tracker)

        let url = URL(string: "https://api.discogs.com/database/search")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "x-discogs-ratelimit-remaining": "3",
                "x-discogs-ratelimit": "60"
            ]
        )!

        await interceptor.didReceive(response, data: Data(), for: URLRequest(url: url))

        let shouldThrottle = await tracker.shouldThrottle(now: Date())
        #expect(shouldThrottle == true)
    }

    @Test func markExhaustedForcesThrottling() async {
        let tracker = RateLimitTracker()
        await tracker.markExhausted(at: Date())

        let shouldThrottle = await tracker.shouldThrottle(now: Date())
        #expect(shouldThrottle == true)
    }
}
