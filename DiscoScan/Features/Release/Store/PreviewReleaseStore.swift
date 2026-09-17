//
//  PreviewReleaseStore.swift
//  DiscoScan
//

#if DEBUG
import Observation

enum PreviewReleaseStoreScenario {
    case loaded(id: Int)
    case loading(id: Int)
    case failed(id: Int, message: String)
}

@MainActor
@Observable
final class PreviewReleaseStore: ReleaseStoreProtocol {
    private(set) var detailsByID: [Int: ResourceState<ReleaseDetailResponse>] = [:]

    init(scenario: PreviewReleaseStoreScenario) {
        switch scenario {
        case .loaded(let id):
            detailsByID[id] = .loaded(ReleaseFixtures.sampleRelease)
        case .loading(let id):
            detailsByID[id] = .loading
        case .failed(let id, let message):
            detailsByID[id] = .failed(message)
        }
    }

    func detail(for releaseId: Int) -> ResourceState<ReleaseDetailResponse> {
        detailsByID[releaseId] ?? .idle
    }

    func loadRelease(id: Int, forceRefresh: Bool) async {}
}

@MainActor
func previewReleaseStore(_ scenario: PreviewReleaseStoreScenario) -> any ReleaseStoreProtocol {
    PreviewReleaseStore(scenario: scenario)
}
#endif
