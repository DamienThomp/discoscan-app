//
//  RecentSearchPersistence.swift
//  DiscoScan
//

import Foundation

protocol RecentSearchPersistence: Sendable {
    func load() -> [String]
    func save(_ queries: [String])
}

struct UserDefaultsRecentSearchPersistence: RecentSearchPersistence {
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
