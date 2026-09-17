//
//  PreviewWantListStore.swift
//  DiscoScan
//

#if DEBUG
import Observation

enum PreviewWantListStoreScenario {
    case wantsLoaded
    case wantsEmpty
    case wantsFailed(String)
    case wantsLoading
}

@MainActor
@Observable
final class PreviewWantListStore: WantListStoreProtocol {
    private(set) var wants: ResourceState<[WantListItem]> = .idle
    private(set) var isMutating = false
    private(set) var lastMutationError: String?

    init(scenario: PreviewWantListStoreScenario) {
        switch scenario {
        case .wantsLoaded:
            wants = .loaded(WantListFixtures.sampleWants)
        case .wantsEmpty:
            wants = .loaded([])
        case .wantsFailed(let message):
            wants = .failed(message)
        case .wantsLoading:
            wants = .loading
        }
    }

    func sync(with state: AuthSession.State) {}

    func canLoadMore() -> Bool { false }

    func loadWants(page: Int, forceRefresh: Bool) async {}

    func loadMoreWants() async {}

    func addRelease(releaseId: Int, notes: String?, rating: Int?) async {}

    func editRelease(releaseId: Int, notes: String?, rating: Int?) async {}

    func deleteRelease(releaseId: Int) async {}

    func isInWantList(releaseId: Int) -> Bool {
        guard case .loaded(let items) = wants else {
            return false
        }
        return items.contains { $0.id == releaseId }
    }

    func ensureWantsLoaded() async {}
}

@MainActor
func previewWantListStore(_ scenario: PreviewWantListStoreScenario) -> any WantListStoreProtocol {
    PreviewWantListStore(scenario: scenario)
}
#endif
