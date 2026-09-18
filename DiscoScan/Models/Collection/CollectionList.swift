//
//  CollectionList.swift
//  DiscoScan
//

import Foundation

nonisolated struct CollectionItem: Codable {
    let id: String
    let name: String
}

nonisolated struct CollectionList: Codable {
    let items: [CollectionItem]
}
