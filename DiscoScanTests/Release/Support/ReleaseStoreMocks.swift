//
//  ReleaseStoreMocks.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
@testable import DiscoScan

enum ReleaseTestFixtures {
    static let sampleRelease: ReleaseDetailResponse = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(ReleaseDetailResponse.self, from: sampleReleaseJSON)
    }()

    private static let sampleReleaseJSON = Data(
        """
        {
            "title": "Never Gonna Give You Up",
            "id": 249504,
            "artists": [
                {
                    "anv": "",
                    "id": 72872,
                    "join": "",
                    "name": "Rick Astley",
                    "resource_url": "https://api.discogs.com/artists/72872",
                    "role": "",
                    "tracks": ""
                }
            ],
            "data_quality": "Correct",
            "thumb": null,
            "community": {
                "contributors": [],
                "data_quality": "Correct",
                "have": 252,
                "rating": { "average": 3.42, "count": 45 },
                "status": "Accepted",
                "submitter": {
                    "resource_url": "https://api.discogs.com/users/memory",
                    "username": "memory"
                },
                "want": 42
            },
            "companies": [],
            "country": "UK",
            "date_added": "2004-04-30T08:10:05-07:00",
            "date_changed": "2012-12-03T02:50:12-07:00",
            "estimated_weight": 60,
            "extraartists": [],
            "format_quantity": 1,
            "formats": [
                {
                    "descriptions": ["Single"],
                    "name": "Vinyl",
                    "qty": "1"
                }
            ],
            "genres": ["Electronic"],
            "identifiers": [],
            "images": [],
            "labels": [
                {
                    "catno": "PB 41447",
                    "entity_type": "1",
                    "id": 895,
                    "name": "RCA",
                    "resource_url": "https://api.discogs.com/labels/895"
                }
            ],
            "lowest_price": null,
            "master_id": null,
            "master_url": null,
            "notes": null,
            "num_for_sale": null,
            "released": "1987",
            "released_formatted": "1987",
            "resource_url": "https://api.discogs.com/releases/249504",
            "series": [],
            "status": "Accepted",
            "styles": [],
            "tracklist": [],
            "uri": null,
            "videos": [],
            "year": 1987
        }
        """.utf8
    )
}

final class MockReleaseCachedFetcher: CachedFetcherProtocol, @unchecked Sendable {
    private(set) var lastFetch: MockFetchRecord?
    private(set) var fetchCount = 0
    var shouldFail = false

    func fetch<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        scope: CacheScope,
        userScope: String?,
        forceRefresh: Bool
    ) async throws -> E.Response {
        fetchCount += 1
        lastFetch = MockFetchRecord(key: key, forceRefresh: forceRefresh, userScope: userScope)

        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }

        if endpoint is ReleaseDetailEndpoint {
            guard let response = ReleaseTestFixtures.sampleRelease as? E.Response else {
                throw URLError(.badURL)
            }
            return response
        }

        throw URLError(.unsupportedURL)
    }

    func cachedValue<E: EndpointProtocol>(
        _ endpoint: E,
        key: String,
        userScope: String?
    ) async throws -> E.Response? {
        nil
    }
}
