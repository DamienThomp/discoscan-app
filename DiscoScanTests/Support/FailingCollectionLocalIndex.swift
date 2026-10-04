//
//  FailingCollectionLocalIndex.swift
//  DiscoScanTests
//

import Foundation
@testable import DiscoScan

enum FailingCollectionLocalIndexMode: Sendable {
    case failOnceThenSucceed
    case alwaysFail
}

actor FailingCollectionLocalIndex: CollectionLocalIndexProtocol {
    private let delegate: any CollectionLocalIndexProtocol
    private let mode: FailingCollectionLocalIndexMode
    private var upsertLiveAttempts = 0
    private var deleteAttempts = 0

    init(delegate: any CollectionLocalIndexProtocol, mode: FailingCollectionLocalIndexMode) {
        self.delegate = delegate
        self.mode = mode
    }

    func count(username: String) async throws -> Int {
        try await delegate.count(username: username)
    }

    func hasUnsealedGeneration(username: String) async throws -> Bool {
        try await delegate.hasUnsealedGeneration(username: username)
    }

    func allItems(username: String) async throws -> [CollectionReleaseItem] {
        try await delegate.allItems(username: username)
    }

    func contains(instanceId: Int, username: String) async throws -> Bool {
        try await delegate.contains(instanceId: instanceId, username: username)
    }

    func upsertLive(_ item: CollectionReleaseItem, username: String) async throws {
        upsertLiveAttempts += 1
        if shouldFail(attempt: upsertLiveAttempts) {
            throw URLError(.cannotWriteToFile)
        }
        try await delegate.upsertLive(item, username: username)
    }

    func delete(instanceId: Int, username: String) async throws {
        deleteAttempts += 1
        if shouldFail(attempt: deleteAttempts) {
            throw URLError(.cannotWriteToFile)
        }
        try await delegate.delete(instanceId: instanceId, username: username)
    }

    func search(username: String, query: String) async throws -> [CollectionReleaseItem] {
        try await delegate.search(username: username, query: query)
    }

    func clear(username: String) async throws {
        try await delegate.clear(username: username)
    }

    func beginSyncGeneration(username: String) async throws -> Int {
        try await delegate.beginSyncGeneration(username: username)
    }

    func upsertSynced(_ items: [CollectionReleaseItem], username: String, generation: Int) async throws {
        try await delegate.upsertSynced(items, username: username, generation: generation)
    }

    func sweep(username: String, keeping generation: Int) async throws -> Int {
        try await delegate.sweep(username: username, keeping: generation)
    }

    private func shouldFail(attempt: Int) -> Bool {
        switch mode {
        case .failOnceThenSucceed:
            attempt == 1
        case .alwaysFail:
            true
        }
    }
}
