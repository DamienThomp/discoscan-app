//
//  CachedFetcher.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated protocol CachedFetcherProtocol: Sendable {
    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        forceRefresh: Bool
    ) async throws -> E.Response

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String
    ) async throws -> E.Response?

    func invalidate(key: String) async

    func invalidateKeys(matchingPrefix prefix: String) async

    func clearAll() async
}

actor CachedFetcher: CachedFetcherProtocol {
    private struct InflightEntry {
        let id: UUID
        let task: Task<Data, Error>
    }

    private let apiClient: NetworkManagerProtocol
    private let storage: SwiftDataCacheStorage
    private let rateLimitTracker: RateLimitTracker
    private let decoder: JSONDecoder
    private let now: @Sendable () -> Date
    private var inflight: [String: InflightEntry] = [:]
    private var cacheGeneration = 0
    private var keyEpoch: [String: Int] = [:]

    init(
        apiClient: NetworkManagerProtocol,
        storage: SwiftDataCacheStorage,
        rateLimitTracker: RateLimitTracker,
        decoder: JSONDecoder,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.rateLimitTracker = rateLimitTracker
        self.decoder = decoder
        self.now = now
    }

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        forceRefresh: Bool
    ) async throws -> E.Response {
        let currentTime = now()

        if !forceRefresh, let entry = try await storage.entry(for: key),
           entry.isFresh(for: scope, now: currentTime) {
            return try decode(entry.payload, as: E.Response.self)
        }

        if await rateLimitTracker.shouldThrottle(now: currentTime),
           let entry = try await storage.entry(for: key),
           !forceRefresh {
            return try decode(entry.payload, as: E.Response.self)
        }

        let data = try await fetchData(
            endpoint,
            key: key,
            scope: scope
        )
        return try decode(data, as: E.Response.self)
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String
    ) async throws -> E.Response? {
        guard let entry = try await storage.entry(for: key) else {
            return nil
        }
        return try decode(entry.payload, as: E.Response.self)
    }

    func invalidate(key: String) async {
        keyEpoch[key, default: 0] += 1
        if let entry = inflight.removeValue(forKey: key) {
            entry.task.cancel()
        }
        try? await storage.removeEntry(for: key)
    }

    func invalidateKeys(matchingPrefix prefix: String) async {
        for key in inflight.keys where key.hasPrefix(prefix) {
            keyEpoch[key, default: 0] += 1
        }
        for key in inflight.keys.filter({ $0.hasPrefix(prefix) }) {
            if let entry = inflight.removeValue(forKey: key) {
                entry.task.cancel()
            }
        }
        try? await storage.removeEntries(matchingPrefix: prefix)
    }

    func clearAll() async {
        cacheGeneration += 1
        for entry in inflight.values {
            entry.task.cancel()
        }
        inflight.removeAll()
        keyEpoch.removeAll()
        try? await storage.clearAll()
    }

    private func fetchData<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope
    ) async throws -> Data {
        if let existing = inflight[key] {
            return try await existing.task.value
        }

        let requestID = UUID()
        // Unstructured task: shared in-flight work is not cancelled when a single caller's task is cancelled.
        let task = Task<Data, Error> {
            try await self.performNetworkFetch(
                endpoint,
                key: key,
                scope: scope
            )
        }
        let entry = InflightEntry(id: requestID, task: task)
        inflight[key] = entry

        defer {
            if inflight[key]?.id == requestID {
                inflight.removeValue(forKey: key)
            }
        }

        return try await task.value
    }

    private func performNetworkFetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope
    ) async throws -> Data {
        let startedGeneration = cacheGeneration
        let startedKeyEpoch = keyEpoch[key] ?? 0

        do {
            let response = try await apiClient.responseData(for: endpoint)
            guard cacheGeneration == startedGeneration, (keyEpoch[key] ?? 0) == startedKeyEpoch else {
                return response.value
            }
            try await storage.store(
                response.value,
                key: key,
                scope: scope,
                fetchedAt: now()
            )
            return response.value
        } catch let error as NetworkError {
            switch error {
            case .transportError:
                if let entry = try await storage.entry(for: key) {
                    return entry.payload
                }
                throw error
            case .serverError(let statusCode, _, _) where statusCode == 429:
                await rateLimitTracker.markExhausted(at: now())
                if let entry = try await storage.entry(for: key) {
                    return entry.payload
                }
                throw error
            default:
                throw error
            }
        }
    }

    private func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}