//
//  ReleaseStore.swift
//  DiscoScan
//

import Foundation
import NetworkKit
import Observation

@MainActor
@Observable
final class ReleaseStore: ReleaseStoreProtocol {

    private(set) var detailsByID: [Int: ResourceState<ReleaseDetailResponse>] = [:]

    private let cachedFetcher: any CachedFetcherProtocol

    init(cachedFetcher: any CachedFetcherProtocol) {
        self.cachedFetcher = cachedFetcher
    }

    convenience init(dependencies: AppDependencies, cachedFetcher: any CachedFetcherProtocol) {
        self.init(cachedFetcher: cachedFetcher)
    }

    func detail(for releaseId: Int) -> ResourceState<ReleaseDetailResponse> {
        detailsByID[releaseId] ?? .idle
    }

    func loadRelease(id: Int, forceRefresh: Bool = false) async {
        if !forceRefresh, case .loaded = detailsByID[id] {
            return
        }

        let current = detailsByID[id] ?? .idle
        detailsByID[id] = current.beginRefresh()

        do {
            let response = try await cachedFetcher.fetch(
                ReleaseDetailEndpoint(releaseId: id, currAbbr: nil),
                key: Self.cacheKey(releaseId: id),
                scope: .release,
                userScope: nil,
                forceRefresh: forceRefresh
            )
            detailsByID[id] = .loaded(response)
        } catch {
            let inFlight = detailsByID[id] ?? .idle
            detailsByID[id] = inFlight.recoverFromFetchFailure(error.localizedDescription)
        }
    }

    private static func cacheKey(releaseId: Int) -> String {
        "release-\(releaseId)"
    }
}
