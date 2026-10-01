//
//  CollectionFoldersResponse.swift
//  DiscoScan
//


import Foundation

nonisolated struct CollectionFoldersResponse: Codable, Sendable, Equatable {
    let folders: [CollectionFolderResponse]

    var allFolder: CollectionFolderResponse? {
        folders.first { $0.id == .zero }
    }
}

nonisolated struct CollectionFolderResponse: Codable, Sendable, Identifiable, Equatable {
    let id: Int
    let count: Int
    let name: String
    let resourceUrl: String

    var isAllFolder: Bool { id == .zero }
}
