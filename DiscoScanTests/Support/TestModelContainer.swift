//
//  TestModelContainer.swift
//  DiscoScanTests
//

import SwiftData
@testable import DiscoScan

nonisolated enum TestModelContainer {
    static func make() throws -> ModelContainer {
        ModelContainerFactory.makeInMemoryContainer()
    }
}
