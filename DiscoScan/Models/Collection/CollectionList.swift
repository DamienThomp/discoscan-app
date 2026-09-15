//
//  CollectionList.swift
//  DiscoScan
//
//  Created by Damien L Thompson on 2026-09-14.
//

import Foundation

nonisolated struct CollectionItem: Codable {
    let id: String
    let name: String
}

nonisolated struct CollectionList: Codable {
    let items: [CollectionItem]
}
