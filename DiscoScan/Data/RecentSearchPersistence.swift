//
//  RecentSearchPersistence.swift
//  DiscoScan
//

import Foundation

nonisolated protocol RecentSearchPersistence: Sendable {
    func load() -> [String]
    func save(_ queries: [String])
}

// UserDefaults is thread-safe, and the SDK does not mark the class Sendable.
nonisolated struct UserDefaultsRecentSearchPersistence: RecentSearchPersistence, @unchecked Sendable {
    private static let key = "recentSearchQueries"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [String] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    func save(_ queries: [String]) {
        guard let data = try? JSONEncoder().encode(queries) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
