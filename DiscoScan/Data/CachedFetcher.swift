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
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response?
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
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        let namespacedKey = CachePolicy.namespacedKey(key, userScope: userScope)
        let currentTime = now()

        if !forceRefresh, let entry = try await storage.entry(for: namespacedKey),
           entry.isFresh(for: scope, now: currentTime) {
            return try decode(entry.payload, as: E.Response.self)
        }

        if await rateLimitTracker.shouldThrottle(now: currentTime),
           let entry = try await storage.entry(for: namespacedKey),
           !forceRefresh {
            return try decode(entry.payload, as: E.Response.self)
        }

        let data = try await fetchData(
            endpoint,
            namespacedKey: namespacedKey,
            key: key,
            scope: scope,
            userScope: userScope
        )
        return try decode(data, as: E.Response.self)
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        let namespacedKey = CachePolicy.namespacedKey(key, userScope: userScope)
        guard let entry = try await storage.entry(for: namespacedKey) else {
            return nil
        }
        return try decode(entry.payload, as: E.Response.self)
    }

    private func fetchData<E: EndpointProtocol>(
        _ endpoint: E,
        namespacedKey: String,
        key: String,
        scope: CacheScope,
        userScope: String?
    ) async throws -> Data {
        if let existingTask = inflight[namespacedKey] {
            return try await existingTask.value
        }

        let task = Task<Data, Error> {
            try await self.performNetworkFetch(
                endpoint,
                namespacedKey: namespacedKey,
                key: key,
                scope: scope,
                userScope: userScope
            )
        }
        inflight[namespacedKey] = task

        defer {
            inflight.removeValue(forKey: namespacedKey)
        }

        return try await task.value
    }

    private func performNetworkFetch<E: EndpointProtocol>(
        _ endpoint: E,
        namespacedKey: String,
        key: String,
        scope: CacheScope,
        userScope: String?
    ) async throws -> Data {
        do {
            let response = try await apiClient.responseData(for: endpoint)
            try await storage.store(
                response.value,
                key: key,
                scope: scope,
                userScope: userScope,
                fetchedAt: now()
            )
            return response.value
        } catch let error as NetworkError {
            switch error {
            case .transportError:
                if let entry = try await storage.entry(for: namespacedKey) {
                    return entry.payload
                }
                throw error
            case .serverError(let statusCode, _, _) where statusCode == 429:
                await rateLimitTracker.markExhausted(at: now())
                if let entry = try await storage.entry(for: namespacedKey) {
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
