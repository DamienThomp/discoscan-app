//
//  SwiftDataCacheStorage.swift
//  DiscoScan
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataCacheStorage {
    func entry(for namespacedKey: String) throws -> CachedEntry? {
        var descriptor = FetchDescriptor<CachedRecord>(
            predicate: #Predicate { $0.cacheKey == namespacedKey }
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
        userScope: String?,
        fetchedAt: Date
    ) throws {
        let namespacedKey = CachePolicy.namespacedKey(key, userScope: userScope)
        var descriptor = FetchDescriptor<CachedRecord>(
            predicate: #Predicate { $0.cacheKey == namespacedKey }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.payload = payload
            existing.fetchedAt = fetchedAt
            existing.scopeRawValue = scope.rawValue
            existing.userScope = userScope
        } else {
            let record = CachedRecord(
                cacheKey: namespacedKey,
                scopeRawValue: scope.rawValue,
                userScope: userScope,
                payload: payload,
                fetchedAt: fetchedAt
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }

    func clear(userScope: String?) throws {
        if let userScope {
            try modelContext.delete(model: CachedRecord.self, where: #Predicate {
                $0.userScope == userScope
            })
        } else {
            try modelContext.delete(model: CachedRecord.self)
        }

        try modelContext.save()
    }
}
