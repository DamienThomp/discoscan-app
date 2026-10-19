//
//  CollectionLocalIndex.swift
//  DiscoScan
//

import Foundation
import SwiftData

protocol CollectionLocalIndexProtocol: Sendable {
    func count(username: String) async throws -> Int
    func hasUnsealedGeneration(username: String) async throws -> Bool
    func lastSyncedAt(username: String) async throws -> Date?
    func allItems(username: String, sortOrder: CollectionSortOrder) async throws -> [CollectionReleaseItem]
    func contains(instanceId: Int, username: String) async throws -> Bool
    func upsertLive(_ item: CollectionReleaseItem, username: String) async throws
    func delete(instanceId: Int, username: String) async throws
    func clear(username: String) async throws

    func beginSyncGeneration(username: String) async throws -> Int
    func upsertSynced(_ items: [CollectionReleaseItem], username: String, generation: Int) async throws
    func sweep(username: String, keeping generation: Int) async throws -> Int
}

extension CollectionLocalIndexProtocol {
    func allItems(username: String) async throws -> [CollectionReleaseItem] {
        try await allItems(username: username, sortOrder: .desc)
    }
}

@ModelActor
actor CollectionLocalIndex: CollectionLocalIndexProtocol {

    #if DEBUG
    private var saveOverride: (@Sendable () throws -> Void)?

    func setSaveOverride(_ handler: (@Sendable () throws -> Void)?) {
        saveOverride = handler
    }
    #endif

    func count(username: String) throws -> Int {
        let predicate = #Predicate<LocalCollectionItem> { $0.username == username }
        return try modelContext.fetchCount(FetchDescriptor(predicate: predicate))
    }

    func hasUnsealedGeneration(username: String) throws -> Bool {
        try fetchMetadata(username: username)?.hasUnsealedGeneration ?? false
    }

    func lastSyncedAt(username: String) throws -> Date? {
        try fetchMetadata(username: username)?.lastSyncedAt
    }

    func allItems(username: String, sortOrder: CollectionSortOrder) throws -> [CollectionReleaseItem] {
        let records = try modelContext.fetch(fetchDescriptor(username: username, sortOrder: sortOrder))
        return records.map { $0.toCollectionReleaseItem() }
    }

    func contains(instanceId: Int, username: String) throws -> Bool {
        try modelContext.fetchCount(itemDescriptor(instanceId: instanceId, username: username)) > 0
    }

    func upsertLive(_ item: CollectionReleaseItem, username: String) throws {
        try saveAfter {
            let meta = try fetchOrCreateMetadata(username: username)
            try upsertRow(item, username: username, generation: meta.activeGeneration)
        }
    }

    func delete(instanceId: Int, username: String) throws {
        try saveAfter {
            var descriptor = itemDescriptor(instanceId: instanceId, username: username)
            descriptor.fetchLimit = 1
            if let existing = try modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            }
        }
    }

    func clear(username: String) throws {
        try saveAfter {
            let predicate = #Predicate<LocalCollectionItem> { $0.username == username }
            try modelContext.delete(model: LocalCollectionItem.self, where: predicate)
            let metadataPredicate = #Predicate<CollectionSyncMetadata> { $0.username == username }
            try modelContext.delete(model: CollectionSyncMetadata.self, where: metadataPredicate)
        }
    }

    func beginSyncGeneration(username: String) throws -> Int {
        try saveAfter {
            let meta = try fetchOrCreateMetadata(username: username)
            if meta.activeGeneration == meta.sealedGeneration {
                meta.activeGeneration += 1
            }
            return meta.activeGeneration
        }
    }

    func upsertSynced(
        _ items: [CollectionReleaseItem],
        username: String,
        generation: Int
    ) throws {
        try saveAfter {
            guard !items.isEmpty else { return }
            let instanceIds = items.map(\.instanceId)
            let predicate = #Predicate<LocalCollectionItem> {
                $0.username == username && instanceIds.contains($0.instanceId)
            }
            let existingRows = try modelContext.fetch(FetchDescriptor(predicate: predicate))
            var byInstanceId: [Int: LocalCollectionItem] = [:]
            for row in existingRows {
                byInstanceId[row.instanceId] = row
            }
            for item in items {
                if let row = byInstanceId[item.instanceId] {
                    row.apply(item, syncGeneration: generation)
                } else {
                    modelContext.insert(
                        LocalCollectionItem(username: username, item: item, syncGeneration: generation)
                    )
                }
            }
        }
    }

    func sweep(username: String, keeping generation: Int) throws -> Int {
        try saveAfter {
            let predicate = #Predicate<LocalCollectionItem> {
                $0.username == username && $0.syncGeneration < generation
            }
            let staleCount = try modelContext.fetchCount(FetchDescriptor(predicate: predicate))
            try modelContext.delete(model: LocalCollectionItem.self, where: predicate)

            let meta = try fetchOrCreateMetadata(username: username)
            meta.sealedGeneration = generation
            meta.lastSyncedAt = Date()
            return staleCount
        }
    }

    private func saveAfter<T>(_ work: () throws -> T) throws -> T {
        do {
            let result = try work()
            try performSave()
            return result
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func performSave() throws {
        #if DEBUG
        if let saveOverride {
            try saveOverride()
            return
        }
        #endif
        try modelContext.save()
    }

    private func fetchDescriptor(
        username: String,
        sortOrder: CollectionSortOrder
    ) -> FetchDescriptor<LocalCollectionItem> {
        let order: SortOrder = sortOrder == .desc ? .reverse : .forward
        return FetchDescriptor<LocalCollectionItem>(
            predicate: #Predicate { $0.username == username },
            sortBy: [SortDescriptor(\.dateAddedAt, order: order)]
        )
    }

    private func itemDescriptor(instanceId: Int, username: String) -> FetchDescriptor<LocalCollectionItem> {
        FetchDescriptor<LocalCollectionItem>(
            predicate: #Predicate<LocalCollectionItem> {
                $0.username == username && $0.instanceId == instanceId
            }
        )
    }

    private func upsertRow(
        _ item: CollectionReleaseItem,
        username: String,
        generation: Int
    ) throws {
        var descriptor = itemDescriptor(instanceId: item.instanceId, username: username)
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(item, syncGeneration: generation)
        } else {
            modelContext.insert(
                LocalCollectionItem(username: username, item: item, syncGeneration: generation)
            )
        }
    }

    private func fetchMetadata(username: String) throws -> CollectionSyncMetadata? {
        var descriptor = FetchDescriptor<CollectionSyncMetadata>(
            predicate: #Predicate { $0.username == username }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchOrCreateMetadata(username: String) throws -> CollectionSyncMetadata {
        if let existing = try fetchMetadata(username: username) {
            return existing
        }

        let created = CollectionSyncMetadata(username: username)
        modelContext.insert(created)
        return created
    }
}
