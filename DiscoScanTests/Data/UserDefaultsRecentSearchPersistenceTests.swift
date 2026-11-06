//
//  UserDefaultsRecentSearchPersistenceTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct UserDefaultsRecentSearchPersistenceTests {

    @Test func `save and load round trip`() {
        let defaults = makeDefaults()
        let persistence = UserDefaultsRecentSearchPersistence(defaults: defaults)

        persistence.save(["Kind of Blue", "Bitches Brew"])
        #expect(persistence.load() == ["Kind of Blue", "Bitches Brew"])
    }

    @Test func `load returns empty when key missing`() {
        let defaults = makeDefaults()
        let persistence = UserDefaultsRecentSearchPersistence(defaults: defaults)
        #expect(persistence.load().isEmpty)
    }

    @Test func `load returns empty when data is corrupt`() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: "recentSearchQueries")
        let persistence = UserDefaultsRecentSearchPersistence(defaults: defaults)
        #expect(persistence.load().isEmpty)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "UserDefaultsRecentSearchPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
