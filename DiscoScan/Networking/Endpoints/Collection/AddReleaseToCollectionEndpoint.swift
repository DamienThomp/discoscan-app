//
//  AddReleaseToCollectionEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct AddReleaseToCollectionEndpoint: EndpointProtocol {
    typealias Response = AddReleaseToCollectionResponse

    let username: String
    let folderId: Int
    let releaseId: Int

    init(username: String, folderId: Int = 1, releaseId: Int) {
        self.username = username
        self.folderId = folderId
        self.releaseId = releaseId
    }

    var host: APIHost { .discogs }
    var path: String {
        "users/\(username)/collection/folders/\(folderId)/releases/\(releaseId)"
    }
    var httpMethod: HTTPMethod { .post }
}
