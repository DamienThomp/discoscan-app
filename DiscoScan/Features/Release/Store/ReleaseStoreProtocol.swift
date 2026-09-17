//
//  ReleaseStoreProtocol.swift
//  DiscoScan
//

import Foundation
import Observation

@MainActor
protocol ReleaseStoreProtocol: AnyObject, Observable {
    func detail(for releaseId: Int) -> ResourceState<ReleaseDetailResponse>
    func loadRelease(id: Int, forceRefresh: Bool) async
}

extension ReleaseStoreProtocol {
    func loadRelease(id: Int) async {
        await loadRelease(id: id, forceRefresh: false)
    }
}
