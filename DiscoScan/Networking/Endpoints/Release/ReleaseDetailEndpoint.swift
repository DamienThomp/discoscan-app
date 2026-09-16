//
//  ReleaseDetailEndpoint.swift
//  DiscoScan
//

import Foundation
import NetworkKit

nonisolated struct ReleaseDetailEndpoint: EndpointProtocol {
    typealias Response = ReleaseDetailResponse

    let releaseId: Int
    let currAbbr: CurrencyAbbreviations?

    var path: String { "releases/\(releaseId)" }
    var host: APIHost { .discogs }
    var httpMethod: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? {
        guard let currAbbr else { return nil }
        return [URLQueryItem(name: "curr_abbr", value: currAbbr.rawValue)]
    }
}
