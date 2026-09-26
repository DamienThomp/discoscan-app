//
//  AppleMusicCatalogService.swift
//  DiscoScan
//

import Foundation
import MusicKit

struct AppleMusicCatalogService: AppleMusicCatalogProtocol {
    func albumURL(for release: ReleaseDetailResponse) async -> URL? {

        guard await MusicAuthorization.request() == .authorized else {
            return nil
        }

        if let barcode = release.barcode, let url = await lookup(barcode: barcode) {
            return url
        }

        let artist = release.primaryArtistName
        let title = release.title

        if let url = await search(term: "\(artist) \(title)") {
            return url
        }

        if let year = release.displayYear {
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
