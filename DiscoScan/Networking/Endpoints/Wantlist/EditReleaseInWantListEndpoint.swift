//
//  EditReleaseInWantListEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct EditReleaseInWantListEndpoint: EndpointProtocol {
    typealias Response = WantListItem

    let username: String
    let releaseId: Int
    let notes: String?
    let rating: Int?

    init(username: String, releaseId: Int, notes: String? = nil, rating: Int? = nil) {
        self.username = username
        self.releaseId = releaseId
        self.notes = notes
        self.rating = rating
    }

    var host: APIHost { .discogs }
    var path: String { "users/\(username)/wants/\(releaseId)" }
    var httpMethod: HTTPMethod { .post }

    var body: (any Encodable & Sendable)? {
        WantListItemRequestBody(notes: notes, rating: rating)
    }
}
