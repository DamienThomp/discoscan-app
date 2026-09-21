//
//  DiscogsUserProfile.swift
//  DiscoScan
//

import Foundation

nonisolated struct DiscogsUserProfile: Codable, Sendable, Equatable, Hashable {
    let username: String
    let name: String?
    let profile: String?
    let location: String?
    let registered: String?
    let numCollection: Int?
    let avatarUrl: String?

    var avatarImageURL: URL? {
        guard let avatarUrl, !avatarUrl.isEmpty else { return nil }
        return URL(string: avatarUrl)
    }
}
