//
//  TestModelContainer.swift
//  DiscoScanTests
//

import SwiftData
@testable import DiscoScan

enum TestModelContainer {
    static func make() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: CachedRecord.self, configurations: configuration)
    }
}
