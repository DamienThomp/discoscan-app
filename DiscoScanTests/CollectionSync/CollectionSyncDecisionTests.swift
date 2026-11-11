//
//  CollectionSyncDecisionTests.swift
//  DiscoScanTests
//

import Testing
@testable import DiscoScan

struct CollectionSyncDecisionTests {

    @Test func `Unsealed wins over count drift`() {
        let health = CollectionSyncDecision.deriveIndexHealth(
            localTotal: 1,
            remoteTotal: 5,
            isUnsealed: true,
            isStale: false
        )
        if case .unsealed(let local, let remote) = health {
            #expect(local == 1)
            #expect(remote == 5)
        } else {
            Issue.record("Expected unsealed")
        }
    }

    @Test func `Count drift when sealed`() {
        let health = CollectionSyncDecision.deriveIndexHealth(
            localTotal: 0,
            remoteTotal: 10,
            isUnsealed: false,
            isStale: true
        )
        if case .countDrift(let local, let remote) = health {
            #expect(local == 0)
            #expect(remote == 10)
        } else {
            Issue.record("Expected countDrift")
        }
    }

    @Test func `Sealed fresh when counts match`() {
        let health = CollectionSyncDecision.deriveIndexHealth(
            localTotal: 42,
            remoteTotal: 42,
            isUnsealed: false,
            isStale: false
        )
        #expect(health == .sealedFresh(matchedCount: 42))
    }

    @Test func `Sealed stale when counts match but stale`() {
        let health = CollectionSyncDecision.deriveIndexHealth(
            localTotal: 42,
            remoteTotal: 42,
            isUnsealed: false,
            isStale: true
        )
        #expect(health == .sealedStale(matchedCount: 42))
    }

    @Test func `Sealed fresh automatic skips sync`() {
        let action = CollectionSyncDecision.decideSyncAction(
            health: .sealedFresh(matchedCount: 10),
            intent: .automatic
        )
        #expect(action == .skip)
    }

    @Test func `Sealed fresh user initiated shows progress`() {
        let action = CollectionSyncDecision.decideSyncAction(
            health: .sealedFresh(matchedCount: 10),
            intent: .userInitiated
        )
        #expect(action == .fullSync(visibility: .showProgress))
    }

    @Test func `Sealed stale automatic syncs silently`() {
        let action = CollectionSyncDecision.decideSyncAction(
            health: .sealedStale(matchedCount: 10),
            intent: .automatic
        )
        #expect(action == .fullSync(visibility: .silent))
    }

    @Test func `Unsealed matching counts automatic is silent`() {
        let action = CollectionSyncDecision.decideSyncAction(
            health: .unsealed(local: 5, remote: 5),
            intent: .automatic
        )
        #expect(action == .fullSync(visibility: .silent))
    }

    @Test func `Repair always paginates silently for drift`() {
        let action = CollectionSyncDecision.decideSyncAction(
            health: .countDrift(local: 1, remote: 2),
            intent: .repair
        )
        #expect(action == .fullSync(visibility: .silent))
    }
}
