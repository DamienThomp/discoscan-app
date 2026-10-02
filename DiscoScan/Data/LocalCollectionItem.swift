//
//  LocalCollectionItem.swift
//  DiscoScan
//

import Foundation
import SwiftData

@Model
nonisolated final class LocalCollectionItem {
    var username: String
    var instanceId: Int
    var releaseId: Int
    var folderId: Int
    var dateAdded: String
    var syncGeneration: Int
    var artistName: String
    var title: String
    var labelName: String
    var catno: String
    var year: Int?
    var searchableText: String
    var thumbURLString: String?
    var coverImageURLString: String?
    var resourceURLString: String?

    init(
        username: String,
        item: CollectionReleaseItem,
        syncGeneration: Int
    ) {
        self.username = username
        self.instanceId = item.instanceId
        self.releaseId = item.releaseId
        self.folderId = item.folderId
        self.dateAdded = item.dateAdded
        self.syncGeneration = syncGeneration
        let info = item.basicInformation
        let artistName = info.primaryArtistName
        let title = info.title
        let labelName = info.labels.first?.name ?? ""
        let catno = info.labels.first?.catno ?? ""
        let year = info.year
        self.artistName = artistName
        self.title = title
        self.labelName = labelName
        self.catno = catno
        self.year = year
        self.searchableText = Self.makeSearchableText(
            artist: artistName,
            title: title,
            label: labelName,
            catno: catno,
            year: year
        )
        self.thumbURLString = info.thumb?.absoluteString
        self.coverImageURLString = info.coverImage?.absoluteString
        self.resourceURLString = info.resourceURL?.absoluteString
    }

    func apply(_ item: CollectionReleaseItem, syncGeneration: Int) {
        releaseId = item.releaseId
        folderId = item.folderId
        dateAdded = item.dateAdded
        self.syncGeneration = syncGeneration
        let info = item.basicInformation
        artistName = info.primaryArtistName
        title = info.title
        labelName = info.labels.first?.name ?? ""
        catno = info.labels.first?.catno ?? ""
        year = info.year
        searchableText = Self.makeSearchableText(
            artist: artistName,
            title: title,
            label: labelName,
            catno: catno,
            year: year
        )
        thumbURLString = info.thumb?.absoluteString
        coverImageURLString = info.coverImage?.absoluteString
        resourceURLString = info.resourceURL?.absoluteString
    }

    func toCollectionReleaseItem() -> CollectionReleaseItem {
        CollectionReleaseItem(
            releaseId: releaseId,
            instanceId: instanceId,
            folderId: folderId,
            dateAdded: dateAdded,
            basicInformation: ReleaseBasicInformation(
                id: releaseId,
                title: title,
                year: year,
                thumb: thumbURLString.flatMap(URL.init(string:)),
                coverImage: coverImageURLString.flatMap(URL.init(string:)),
                resourceURL: resourceURLString.flatMap(URL.init(string:)),
                artists: artistName.isEmpty ? [] : [DiscogsArtist(id: 0, name: artistName)],
                labels: labelName.isEmpty
                    ? []
                    : [DiscogsLabel(id: 0, name: labelName, catno: catno.isEmpty ? nil : catno)],
                formats: []
            )
        )
    }

    static func makeSearchableText(
        artist: String,
        title: String,
        label: String,
        catno: String,
        year: Int?
    ) -> String {
        [artist, title, label, catno, year.map(String.init) ?? ""]
            .joined(separator: " ")
            .lowercased()
    }
}

nonisolated enum CollectionSearchMatching {
    static func matches(query: String, searchableText: String) -> Bool {
        let tokens = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        guard !tokens.isEmpty else { return true }
        return tokens.allSatisfy { searchableText.contains($0) }
    }
}
