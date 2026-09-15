//
//  CachePolicy.swift
//  DiscoScan
//

import Foundation

nonisolated enum CacheScope: String, Sendable, CaseIterable {
    case identity
    case search
    case wantlist
    case collection
    case release

    var ttl: TimeInterval {
        switch self {
        case .identity:
            60 * 60 * 24
        case .search:
            60 * 15
        case .wantlist,.collection:
            60 * 60
        case .release:
            60 * 60 * 24 * 7
        }
    }
}

nonisolated struct CachedEntry: Sendable {
    let payload: Data
    let fetchedAt: Date

    func isFresh(for scope: CacheScope, now: Date) -> Bool {
        now.timeIntervalSince(fetchedAt) < scope.ttl
    }
}

nonisolated enum CachePolicy {
    static func namespacedKey(_ key: String, userScope: String?) -> String {
        "\(userScope ?? "-")|\(key)"
    }
}
