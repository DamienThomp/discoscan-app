//
//  SleeveIdentification.swift
//  DiscoScan
//

import Foundation

nonisolated struct SleeveIdentification: Decodable, Sendable, Equatable {
    let artist: String?
    let title: String?
    let catalogNumber: String?

    private enum CodingKeys: String, CodingKey {
        case artist
        case title
        case catalogNumber
    }

    // Language models sometimes emit placeholder words instead of omitting a field.
    private static let placeholderValues: Set<String> = ["null", "nil", "none", "n/a", "unknown"]

    init(artist: String?, title: String?, catalogNumber: String?) {
        self.artist = Self.normalized(artist)
        self.title = Self.normalized(title)
        self.catalogNumber = Self.normalized(catalogNumber)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            artist: try container.decodeIfPresent(String.self, forKey: .artist),
            title: try container.decodeIfPresent(String.self, forKey: .title),
            catalogNumber: try container.decodeIfPresent(String.self, forKey: .catalogNumber)
        )
    }

    private static func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              !placeholderValues.contains(trimmed.lowercased())
        else {
            return nil
        }
        return trimmed
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
