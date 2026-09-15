//
//  CollectionFoldersResponse.swift
//  DiscoScan
//


import Foundation

nonisolated struct CollectionFoldersResponse: Codable, Sendable, Equatable {
    let folders: [CollectionFolderResponse]
}

nonisolated struct CollectionFolderResponse: Codable, Sendable, Identifiable, Equatable {
    let id: Int
    let count: Int
    let name: String
    let resourceUrl: String
}
