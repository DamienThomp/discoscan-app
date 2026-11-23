//
//  AppleMusicCatalogService.swift
//  DiscoScan
//

import Foundation
import MusicKit

nonisolated struct AppleMusicCatalogService: AppleMusicCatalogProtocol {
    func albumURL(for release: ReleaseDetailResponse) async -> URL? {
        let barcode = ReleaseDetailDisplay.barcode(for: release)
        let artist = ReleaseDetailDisplay.primaryArtistName(for: release)
        let title = release.title
        let year = ReleaseDetailDisplay.displayYear(for: release)

        guard await MusicAuthorization.request() == .authorized else {
            return nil
        }

        if let barcode, let url = await lookup(barcode: barcode) {
            return url
        }

        if let url = await search(term: "\(artist) \(title)") {
            return url
        }

        if let year {
            return await search(term: "\(artist) \(title) \(year)")
        }

        return nil
    }

    private func lookup(barcode: String) async -> URL? {
        let request = MusicCatalogResourceRequest<Album>(
            matching: \.upc,
            equalTo: barcode
        )
        guard let album = try? await request.response().items.first else { return nil }
        return album.url
    }

    private func search(term: String) async -> URL? {
        let request = MusicCatalogSearchRequest(
            term: term,
            types: [Album.self]
        )
        guard let album = try? await request.response().albums.first else { return nil }
        return album.url
    }
}
