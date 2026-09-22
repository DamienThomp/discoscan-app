//
//  RecentSearchStoreTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct RecentSearchStoreTests {

    @Test func removeDeletesMatchingQueryCaseInsensitively() {
        let defaults = makeDefaults()
        let store = RecentSearchStore(defaults: defaults)

        store.add("Kind of Blue")
        store.add("Bitches Brew")
        store.remove("kind of blue")

        #expect(store.load() == ["Bitches Brew"])
    }

    @Test func removeIgnoresEmptyQuery() {
        let defaults = makeDefaults()
        let store = RecentSearchStore(defaults: defaults)

        store.add("Miles Davis")
        store.remove("   ")

        #expect(store.load() == ["Miles Davis"])
    }

    @Test func clearAllRemovesEveryStoredQuery() {
        let defaults = makeDefaults()
        let store = RecentSearchStore(defaults: defaults)

        store.add("Kind of Blue")
        store.add("Bitches Brew")
        store.clearAll()

        #expect(store.load().isEmpty)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "RecentSearchStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
