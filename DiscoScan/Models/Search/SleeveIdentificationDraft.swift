//
//  SleeveIdentificationDraft.swift
//  DiscoScan
//

import Foundation

nonisolated struct SleeveIdentificationDraft: Sendable, Equatable {
    var artist = ""
    var title = ""
    var catalogNumber = ""

    init() {}

    init(from identification: SleeveIdentification) {
        artist = identification.artist ?? ""
        title = identification.title ?? ""
        catalogNumber = identification.catalogNumber ?? ""
    }

    var searchQuery: String {
        composedSleeveSearchQuery(artist, title, catalogNumber)
    }

    var isEmpty: Bool {
        searchQuery.isEmpty
    }
}
