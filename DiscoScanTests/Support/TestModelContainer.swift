//
//  TestModelContainer.swift
//  DiscoScanTests
//

import SwiftData
@testable import DiscoScan

enum TestModelContainer {
    static func make() throws -> ModelContainer {
        ModelContainerFactory.makeInMemoryContainer()
    }
}
