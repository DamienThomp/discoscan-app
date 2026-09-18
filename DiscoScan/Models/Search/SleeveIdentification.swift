//
//  SleeveIdentification.swift
//  DiscoScan
//

import Foundation

nonisolated struct SleeveIdentification: Decodable, Sendable, Equatable {
    let artist: String?
    let title: String?
    let catalogNumber: String?

    init(artist: String?, title: String?, catalogNumber: String?) {
        self.artist = artist
        self.title = title
        self.catalogNumber = catalogNumber
    }

    var searchQuery: String {
        composedSleeveSearchQuery(artist, title, catalogNumber)
    }

    var isEmpty: Bool {
        searchQuery.isEmpty
    }
}

nonisolated func composedSleeveSearchQuery(_ values: String?...) -> String {
    values
        .compactMap { value in
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        .joined(separator: " ")
}
