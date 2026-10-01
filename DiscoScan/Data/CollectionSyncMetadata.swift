//
//  CollectionSyncMetadata.swift
//  DiscoScan
//

import Foundation
import SwiftData

@Model
nonisolated final class CollectionSyncMetadata {
    @Attribute(.unique) var username: String
    var localCount: Int
    var lastSyncedAt: Date?
    var activeGeneration: Int
    var sealedGeneration: Int

    init(username: String) {
        self.username = username
        self.localCount = 0
        self.lastSyncedAt = nil
        self.activeGeneration = 0
        self.sealedGeneration = 0
    }

    var hasUnsealedGeneration: Bool {
        activeGeneration > sealedGeneration
    }
}
