//
//  SearchResponseTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct SearchResponseTests {
    private let mockJSON = Data(
        """
        {
          "pagination": {
            "page": 1,
            "pages": 3,
            "per_page": 25,
            "items": 67,
            "urls": {}
          },
          "results": [
            {
              "country": "Germany",
              "year": "1976",
              "format": ["Vinyl", "LP", "Album", "Stereo"],
              "type": "master",
              "id": 29301,
              "catno": "BRAIN 1088",
              "title": "Klaus Schulze - Moondawn",
              "thumb": "",
              "resource_url": "https://api.discogs.com/masters/29301"
            },
            {
              "id": 10360,
              "type": "artist",
              "title": "Klaus Schulze",
              "thumb": "",
              "resource_url": "https://api.discogs.com/artists/10360"
            },
            {
              "country": "France",
              "year": "1976",
              "format": ["Vinyl", "LP", "Album", "Stereo"],
              "type": "release",
              "id": 61574,
              "catno": "ISA 9001",
              "title": "Klaus Schulze - Moondawn",
              "thumb": "",
              "resource_url": "https://api.discogs.com/releases/61574"
            }
          ]
        }
        """.utf8
    )

    @Test func decodesMixedResultTypes() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(SearchResponse.self, from: mockJSON)

        #expect(response.pagination.page == 1)
        #expect(response.pagination.perPage == 25)
        #expect(response.pagination.items == 67)
        #expect(response.results.count == 3)

        let master = try #require(response.results.first)
        #expect(master.type == "master")
        #expect(master.format == ["Vinyl", "LP", "Album", "Stereo"])
        #expect(master.catno == "BRAIN 1088")
        #expect(master.thumb == nil)
        #expect(master.resourceURL?.absoluteString == "https://api.discogs.com/masters/29301")

        let artist = response.results[1]
        #expect(artist.type == "artist")
        #expect(artist.format == nil)
        #expect(artist.catno == nil)

        let release = response.results[2]
        #expect(release.type == "release")
        #expect(release.catno == "ISA 9001")
    }

    @Test func paginationAfterRemovingOneItemUpdatesTotals() {
        let pagination = SearchPagination(page: 2, pages: 2, perPage: 50, items: 60)

        let updated = pagination.afterRemovingOneItem()

        #expect(updated.page == 2)
        #expect(updated.items == 59)
        #expect(updated.pages == 2)
    }
}
