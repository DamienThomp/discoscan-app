//
//  DiscogsIdentity.swift
//  DiscoScan
//

import Foundation

nonisolated struct DiscogsIdentity: Codable, Sendable, Equatable, Hashable {
    let id: Int
    let username: String
    let resourceURL: URL?
    let consumerName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case resourceURL
        case consumerName
    }
}
