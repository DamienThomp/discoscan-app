//
//  CollectionItemSnapshot.swift
//  DiscoScan
//

import Foundation

nonisolated struct CollectionItemSnapshot: Sendable, Equatable {
    let title: String
    let year: Int?
    let thumb: URL?
    let coverImage: URL?
    let resourceURL: URL?
    let artists: [DiscogsArtist]
    let labels: [DiscogsLabel]
    let formats: [DiscogsFormat]

    func asBasicInformation(releaseId: Int) -> ReleaseBasicInformation {
        ReleaseBasicInformation(
            id: releaseId,
            title: title,
            year: year,
            thumb: thumb,
            coverImage: coverImage,
            resourceURL: resourceURL,
            artists: artists,
            labels: labels,
            formats: formats
        )
    }

    func asCollectionReleaseItem(
        releaseId: Int,
        instanceId: Int,
        folderId: Int,
        dateAdded: String
    ) -> CollectionReleaseItem {
        CollectionReleaseItem(
            releaseId: releaseId,
            instanceId: instanceId,
            folderId: folderId,
            dateAdded: dateAdded,
            basicInformation: asBasicInformation(releaseId: releaseId)
        )
    }
}

extension ReleaseDetailResponse {
    func asCollectionSnapshot() -> CollectionItemSnapshot {
        CollectionItemSnapshot(
            title: title,
            year: year,
            thumb: thumb,
            coverImage: images.first?.uri ?? thumb,
            resourceURL: resourceURL,
            artists: artists.map { DiscogsArtist(id: $0.id, name: $0.name) },
            labels: labels.map { DiscogsLabel(id: $0.id, name: $0.name, catno: $0.catno) },
            formats: formats
        )
    }
}
