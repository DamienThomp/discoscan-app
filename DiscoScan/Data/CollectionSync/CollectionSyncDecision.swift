//
//  CollectionSyncDecision.swift
//  DiscoScan
//

import Foundation

/// Persisted index shape plus remote folder count after the folders API call.
nonisolated enum CollectionIndexHealth: Equatable, Sendable {
    case emptyLocal(remoteTotal: Int)
    case countDrift(local: Int, remote: Int)
    case unsealed(local: Int, remote: Int)
    case sealedStale(matchedCount: Int)
    case sealedFresh(matchedCount: Int)
}

nonisolated enum CollectionSyncIntent: Sendable {
    /// ensureFolderZeroIndexReady, foreground, non-forced load.
    case automatic
    /// Pull to refresh and explicit force from the UI.
    case userInitiated
    /// Local index repair after a partial mutation.
    case repair
}

nonisolated enum SyncProgressVisibility: Equatable, Sendable {
    case silent
    case showProgress
}

nonisolated enum CollectionSyncAction: Equatable, Sendable {
    case skip
    case fullSync(visibility: SyncProgressVisibility)
}

nonisolated enum CollectionSyncDecision {
    static func deriveIndexHealth(
        localTotal: Int,
        remoteTotal: Int,
        isUnsealed: Bool,
        isStale: Bool
    ) -> CollectionIndexHealth {
        if isUnsealed {
            return .unsealed(local: localTotal, remote: remoteTotal)
        }
        if localTotal != remoteTotal {
            return .countDrift(local: localTotal, remote: remoteTotal)
        }
        if localTotal == 0, remoteTotal > 0 {
            return .emptyLocal(remoteTotal: remoteTotal)
        }
        if isStale {
            return .sealedStale(matchedCount: localTotal)
        }
        return .sealedFresh(matchedCount: localTotal)
    }

    static func decideSyncAction(
        health: CollectionIndexHealth,
        intent: CollectionSyncIntent
    ) -> CollectionSyncAction {
        switch (health, intent) {
        case (.sealedFresh, .automatic):
            return .skip

        case (.sealedFresh, .userInitiated):
            return .fullSync(visibility: .showProgress)
        case (.sealedFresh, .repair):
            return .fullSync(visibility: .silent)

        case (.sealedStale, .automatic):
            return .fullSync(visibility: .silent)
        case (.sealedStale, .userInitiated):
            return .fullSync(visibility: .showProgress)
        case (.sealedStale, .repair):
            return .fullSync(visibility: .silent)

        case (.unsealed(let local, let remote), .automatic):
            let visibility: SyncProgressVisibility = local == remote ? .silent : .showProgress
            return .fullSync(visibility: visibility)
        case (.unsealed, .userInitiated):
            return .fullSync(visibility: .showProgress)
        case (.unsealed, .repair):
            return .fullSync(visibility: .silent)

        case (.countDrift, .automatic):
            return .fullSync(visibility: .showProgress)
        case (.countDrift, .userInitiated):
            return .fullSync(visibility: .showProgress)
        case (.countDrift, .repair):
            return .fullSync(visibility: .silent)

        case (.emptyLocal, .automatic):
            return .fullSync(visibility: .showProgress)
        case (.emptyLocal, .userInitiated):
            return .fullSync(visibility: .showProgress)
        case (.emptyLocal, .repair):
            return .fullSync(visibility: .silent)
        }
    }
}
