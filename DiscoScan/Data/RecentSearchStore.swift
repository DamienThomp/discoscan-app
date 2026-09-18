//
//  RecentSearchStore.swift
//  DiscoScan
//

import Foundation

struct RecentSearchStore: Sendable {
    private static let storageKey = "recentSearches"
    private static let limit = 10

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [String] {
        defaults.stringArray(forKey: Self.storageKey) ?? []
    }

    func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var recent = load().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        recent.insert(trimmed, at: 0)
        if recent.count > Self.limit {
            recent = Array(recent.prefix(Self.limit))
        }
        defaults.set(recent, forKey: Self.storageKey)
    }

    func remove(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let recent = load().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        defaults.set(recent, forKey: Self.storageKey)
    }
}
