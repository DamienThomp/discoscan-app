//
//  CollectionLocalIndex.swift
//  DiscoScan
//

import Foundation
import SwiftData

protocol CollectionLocalIndexProtocol: Sendable {
    func count(username: String) async throws -> Int
    func hasUnsealedGeneration(username: String) async throws -> Bool
    func allItems(username: String) async throws -> [CollectionReleaseItem]
    func upsertLive(_ item: CollectionReleaseItem, username: String) async throws
    func delete(instanceId: Int, username: String) async throws
    func search(username: String, query: String) async throws -> [CollectionReleaseItem]
    func clear(username: String) async throws

    func beginSyncGeneration(username: String) async throws -> Int
    func upsertSynced(_ items: [CollectionReleaseItem], username: String, generation: Int) async throws
    func sweep(username: String, keeping generation: Int) async throws -> Int
}

@ModelActor
actor CollectionLocalIndex: CollectionLocalIndexProtocol {
    func count(username: String) throws -> Int {
        try modelContext.fetchCount(fetchDescriptor(username: username))
    }

    func hasUnsealedGeneration(username: String) throws -> Bool {
        try fetchOrCreateMetadata(username: username).hasUnsealedGeneration
    }

    func allItems(username: String) throws -> [CollectionReleaseItem] {
        let records = try modelContext.fetch(fetchDescriptor(username: username))
        return records.map { $0.toCollectionReleaseItem() }
    }

    func upsertLive(_ item: CollectionReleaseItem, username: String) throws {
        let meta = try fetchOrCreateMetadata(username: username)
        try upsertRow(item, username: username, generation: meta.activeGeneration)
        meta.localCount = try count(username: username)
        try modelContext.save()
    }

    func delete(instanceId: Int, username: String) throws {
        let predicate = #Predicate<LocalCollectionItem> {
            $0.username == username && $0.instanceId == instanceId
        }
        try modelContext.delete(model: LocalCollectionItem.self, where: predicate)
        let meta = try fetchOrCreateMetadata(username: username)
        meta.localCount = try count(username: username)
        try modelContext.save()
    }

    func search(username: String, query: String) throws -> [CollectionReleaseItem] {
        try allItems(username: username).filter { item in
            let searchable = LocalCollectionItem.makeSearchableText(
                artist: item.basicInformation.primaryArtistName,
                title: item.basicInformation.title,
                label: item.basicInformation.labels.first?.name ?? "",
                catno: item.basicInformation.labels.first?.catno ?? "",
                year: item.basicInformation.year
            )
            return CollectionSearchMatching.matches(query: query, searchableText: searchable)
        }
    }

    func clear(username: String) throws {
        let predicate = #Predicate<LocalCollectionItem> { $0.username == username }
        try modelContext.delete(model: LocalCollectionItem.self, where: predicate)
        let metadataPredicate = #Predicate<CollectionSyncMetadata> { $0.username == username }
        try modelContext.delete(model: CollectionSyncMetadata.self, where: metadataPredicate)
        try modelContext.save()
    }

    func beginSyncGeneration(username: String) throws -> Int {
        let meta = try fetchOrCreateMetadata(username: username)
        if meta.activeGeneration == meta.sealedGeneration {
            meta.activeGeneration += 1
        }
        try modelContext.save()
        return meta.activeGeneration
    }

    func upsertSynced(
        _ items: [CollectionReleaseItem],
        username: String,
        generation: Int
    ) throws {
        for item in items {
            try upsertRow(item, username: username, generation: generation)
        }
        try modelContext.save()
    }

    func sweep(username: String, keeping generation: Int) throws -> Int {
        let predicate = #Predicate<LocalCollectionItem> {
            $0.username == username && $0.syncGeneration < generation
        }
        let staleCount = try modelContext.fetchCount(FetchDescriptor(predicate: predicate))
        try modelContext.delete(model: LocalCollectionItem.self, where: predicate)

        let meta = try fetchOrCreateMetadata(username: username)
        meta.sealedGeneration = generation
        meta.localCount = try count(username: username)
        meta.lastSyncedAt = Date()
        try modelContext.save()
        return staleCount
    }

    private func fetchDescriptor(username: String) -> FetchDescriptor<LocalCollectionItem> {
        var descriptor = FetchDescriptor<LocalCollectionItem>(
            predicate: #Predicate { $0.username == username },
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return descriptor
    }

    private func upsertRow(
        _ item: CollectionReleaseItem,
        username: String,
        generation: Int
    ) throws {
        let instanceId = item.instanceId
        let predicate = #Predicate<LocalCollectionItem> {
            $0.username == username && $0.instanceId == instanceId
        }
        var descriptor = FetchDescriptor<LocalCollectionItem>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(item, syncGeneration: generation)
        } else {
            modelContext.insert(
                LocalCollectionItem(username: username, item: item, syncGeneration: generation)
            )
        }
    }

    private func fetchOrCreateMetadata(username: String) throws -> CollectionSyncMetadata {
        var descriptor = FetchDescriptor<CollectionSyncMetadata>(
            predicate: #Predicate { $0.username == username }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let created = CollectionSyncMetadata(username: username)
        modelContext.insert(created)
        return created
    }
}
