//
//  ReleaseStoreEnvironment.swift
//  DiscoScan
//

import SwiftUI

@MainActor
@Observable
private final class UnimplementedReleaseStore: ReleaseStoreProtocol {
    func detail(for releaseId: Int) -> ResourceState<ReleaseDetailResponse> {
        fatalError("releaseStore environment value was not injected.")
    }

    func loadRelease(id: Int, forceRefresh: Bool) async {
        fatalError("releaseStore environment value was not injected.")
    }
}

private let unimplementedReleaseStore = UnimplementedReleaseStore()

extension EnvironmentValues {
    @Entry var releaseStore: any ReleaseStoreProtocol = unimplementedReleaseStore
}
