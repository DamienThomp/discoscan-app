//
//  RateLimitTracker.swift
//  DiscoScan
//

import Foundation

actor RateLimitTracker {
    static let throttleThreshold = 5

    private var remaining: Int?

    func record(remaining: Int, limit: Int, at: Date) {
        self.remaining = remaining
    }

    func markExhausted(at: Date) {
        remaining = 0
    }

    func shouldThrottle(now: Date) -> Bool {
        guard let remaining else { return false }
        return remaining < Self.throttleThreshold
    }
}
