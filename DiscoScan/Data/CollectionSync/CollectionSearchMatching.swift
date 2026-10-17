//
//  CollectionSearchMatching.swift
//  DiscoScan
//

import Foundation

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

extension CollectionReleaseItem {
    var searchableText: String {
        let info = basicInformation
        return CollectionSearchText.make(
            artist: info.primaryArtistName,
            title: info.title,
            label: info.labels.first?.name ?? "",
            catno: info.labels.first?.catno ?? "",
            year: info.year
        )
    }
}

nonisolated enum CollectionSearchText {
    static func make(
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
