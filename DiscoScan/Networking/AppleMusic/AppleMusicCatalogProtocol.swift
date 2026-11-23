//
//  AppleMusicCatalogProtocol.swift
//  DiscoScan
//

import Foundation

nonisolated protocol AppleMusicCatalogProtocol: Sendable {
    func albumURL(for release: ReleaseDetailResponse) async -> URL?
}
