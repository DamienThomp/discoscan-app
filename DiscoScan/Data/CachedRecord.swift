//
//  CachedRecord.swift
//  DiscoScan
//

import Foundation
import SwiftData

@Model
nonisolated final class CachedRecord {
    @Attribute(.unique) var cacheKey: String
    var scopeRawValue: String
    var payload: Data
    var fetchedAt: Date

    init(
        cacheKey: String,
        scopeRawValue: String,
        payload: Data,
        fetchedAt: Date
    ) {
        self.cacheKey = cacheKey
        self.scopeRawValue = scopeRawValue
        self.payload = payload
        self.fetchedAt = fetchedAt
    }
}
