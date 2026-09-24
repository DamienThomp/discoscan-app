//
//  CachedFetcher.swift
//  DiscoScan
//

import Foundation
import NetworkKit

protocol CachedFetcherProtocol: Sendable {
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
}

actor CachedFetcher: CachedFetcherProtocol {
    private let apiClient: NetworkManagerProtocol
    private let storage: SwiftDataCacheStorage
    private let rateLimitTracker: RateLimitTracker
    private let decoder: JSONDecoder
    private let now: @Sendable () -> Date
    private var inflight: [String: Task<Data, Error>] = [:]

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
        try? await storage.removeEntry(for: key)
        inflight.removeValue(forKey: key)
    }

    func invalidateKeys(matchingPrefix prefix: String) async {
        try? await storage.removeEntries(matchingPrefix: prefix)
        inflight.keys.filter { $0.hasPrefix(prefix) }.forEach { inflight.removeValue(forKey: $0) }
    }

    private func fetchData<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope
    ) async throws -> Data {
        if let existingTask = inflight[key] {
            return try await existingTask.value
        }

        let task = Task<Data, Error> {
            try await self.performNetworkFetch(
                endpoint,
                key: key,
                scope: scope
            )
        }
        inflight[key] = task

        defer {
            inflight.removeValue(forKey: key)
        }

        return try await task.value
    }

    private func performNetworkFetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope
    ) async throws -> Data {
        do {
            let response = try await apiClient.responseData(for: endpoint)
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
