//
//  ModelContainerFactory.swift
//  DiscoScan
//

import Foundation
import os
import SwiftData

enum ModelContainerFactory {
    /// Bump when SwiftData models change; mismatched stores are wiped and rebuilt on next launch.
    static let schemaVersion = 2

    private static let schemaVersionKey = "DiscoScan.SwiftData.schemaVersion"
    private static let logger = Logger(subsystem: "com.discoscan", category: "ModelContainer")

    private static var schema: Schema {
        Schema([
            CachedRecord.self,
            LocalCollectionItem.self,
            CollectionSyncMetadata.self
        ])
    }

    static func makePersistentContainer() -> ModelContainer {
        wipeStoreIfSchemaVersionChanged()

        // On-disk store can fail to open (corruption, migration mismatch). One retry after deleting
        // default.store (+ WAL/SHM) often fixes it without nuking unrelated app data.
        do {
            return try openPersistentContainer()
        } catch {
            logger.error("Failed to open ModelContainer: \(error.localizedDescription, privacy: .public)")
            deleteDefaultStoreFiles()
        }

        // If opening still fails, keep the app launchable with an in-memory container; cache and
        // collection index re-populate from network on the next sync.
        do {
            return try openPersistentContainer()
        } catch {
            logger.fault(
                "ModelContainer failed after store wipe; using in-memory store: \(error.localizedDescription, privacy: .public)"
            )
            return makeInMemoryContainer()
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    private static func openPersistentContainer() throws -> ModelContainer {
        let container = try ModelContainer(for: schema)
        UserDefaults.standard.set(schemaVersion, forKey: schemaVersionKey)
        return container
    }

    private static func wipeStoreIfSchemaVersionChanged() {
        let stored = UserDefaults.standard.integer(forKey: schemaVersionKey)
        guard stored != schemaVersion else { return }
        logger.notice("SwiftData schema version changed (\(stored) -> \(self.schemaVersion)); wiping store")
        deleteDefaultStoreFiles()
    }

    private static func deleteDefaultStoreFiles() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let baseNames = ["default.store", "default.store-shm", "default.store-wal"]
        for name in baseNames {
            let url = appSupport.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
    }
}