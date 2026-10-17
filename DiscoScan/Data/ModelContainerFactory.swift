//
//  ModelContainerFactory.swift
//  DiscoScan
//

import Foundation
import os
import SwiftData

enum ModelContainerFactory {
    /// Bump when SwiftData models change; mismatched stores are wiped and rebuilt on next launch.
    static let schemaVersion = 1

    private static let schemaVersionKey = "DiscoScan.SwiftData.schemaVersion"
    private static let logger = Logger(subsystem: "com.discoscan", category: "ModelContainer")

    static func makePersistentContainer() -> ModelContainer {
        wipeStoreIfSchemaVersionChanged()

        let schema = Schema([
            CachedRecord.self,
            LocalCollectionItem.self,
            CollectionSyncMetadata.self
        ])

        do {
            let container = try ModelContainer(for: schema)
            UserDefaults.standard.set(schemaVersion, forKey: schemaVersionKey)
            return container
        } catch {
            logger.error("Failed to open ModelContainer: \(error.localizedDescription, privacy: .public)")
            deleteDefaultStoreFiles()
            do {
                let container = try ModelContainer(for: schema)
                UserDefaults.standard.set(schemaVersion, forKey: schemaVersionKey)
                return container
            } catch {
                logger.fault(
                    "ModelContainer failed after store wipe; using in-memory store: \(error.localizedDescription, privacy: .public)"
                )
                return makeInMemoryContainer(schema: schema)
            }
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            CachedRecord.self,
            LocalCollectionItem.self,
            CollectionSyncMetadata.self
        ])
        return makeInMemoryContainer(schema: schema)
    }

    private static func makeInMemoryContainer(schema: Schema) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
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
