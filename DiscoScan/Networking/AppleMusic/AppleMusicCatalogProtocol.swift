//
//  AppleMusicCatalogProtocol.swift
//  DiscoScan
//

import Foundation

protocol AppleMusicCatalogProtocol: Sendable {
    func albumURL(for release: ReleaseDetailResponse) async -> URL?
}
