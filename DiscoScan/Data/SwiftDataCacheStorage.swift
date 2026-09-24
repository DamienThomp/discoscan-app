//
//  SwiftDataCacheStorage.swift
//  DiscoScan
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataCacheStorage {
    func entry(for key: String) throws -> CachedEntry? {
        var descriptor = FetchDescriptor<CachedRecord>(
            predicate: #Predicate { $0.cacheKey == key }
        )
        descriptor.fetchLimit = 1

        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return CachedEntry(payload: record.payload, fetchedAt: record.fetchedAt)
    }

    func store(
        _ payload: Data,
        key: String,
        scope: CacheScope,
        fetchedAt: Date
    ) throws {
        var descriptor = FetchDescriptor<CachedRecord>(
            predicate: #Predicate { $0.cacheKey == key }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payload = payload
            existing.fetchedAt = fetchedAt
            existing.scopeRawValue = scope.rawValue
        } else {
            let record = CachedRecord(
                cacheKey: key,
                scopeRawValue: scope.rawValue,
                payload: payload,
                fetchedAt: fetchedAt
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }

    func removeEntry(for key: String) throws {
        try modelContext.delete(model: CachedRecord.self, where: #Predicate {
            $0.cacheKey == key
        })
        try modelContext.save()
    }

    func removeEntries(matchingPrefix prefix: String) throws {
        try modelContext.delete(model: CachedRecord.self, where: #Predicate {
            $0.cacheKey.starts(with: prefix)
        })
        try modelContext.save()
    }

    func clearAll() throws {
        try modelContext.delete(model: CachedRecord.self)
        try modelContext.save()
    }
}
