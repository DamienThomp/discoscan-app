//
//  PreviewProfileStore.swift
//  DiscoScan
//

#if DEBUG
import Observation

enum PreviewProfileStoreScenario {
    case loaded
    case loading
    case failed(String)
}

@MainActor
@Observable
final class PreviewProfileStore: ProfileStoreProtocol {
    private(set) var profile: ResourceState<DiscogsUserProfile> = .idle

    init(scenario: PreviewProfileStoreScenario) {
        switch scenario {
        case .loaded:
            profile = .loaded(ProfileFixtures.sample)
        case .loading:
            profile = .loading
        case .failed(let message):
            profile = .failed(message)
        }
    }

    func sync(with state: AuthSession.State) {}

    func loadProfile(forceRefresh: Bool) async {}
}

@MainActor
func previewProfileStore(_ scenario: PreviewProfileStoreScenario) -> any ProfileStoreProtocol {
    PreviewProfileStore(scenario: scenario)
}
#endif
