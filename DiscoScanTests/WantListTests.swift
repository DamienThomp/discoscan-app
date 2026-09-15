//
//  WantListTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct WantListTests {
    private let mockJSON = Data(
        """
        {
          "pagination": {
            "per_page": 50,
            "pages": 1,
            "page": 1,
            "items": 2,
            "urls": {}
          },
          "wants": [
            {
              "rating": 4,
              "basic_information": {
                "formats": [
                  {
                    "text": "Digipak",
                    "qty": "1",
                    "descriptions": ["Album"],
                    "name": "CD"
                  }
                ],
                "thumb": "https://api-img.discogs.com/PsLAcp_I0-EPPkSBaHx2t7dmXTg=/fit-in/150x150/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-1867708-1248886216.jpeg.jpg",
                "cover_image": "https://api-img.discogs.com/PsLAcp_I0-EPPkSBaHx2t7dmXTg=/fit-in/500x500/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-1867708-1248886216.jpeg.jpg",
                "title": "Year Zero",
                "labels": [
                  {
                    "resource_url": "https://api.discogs.com/labels/2311",
                    "entity_type": "",
                    "catno": "B0008764-02",
                    "id": 2311,
                    "name": "Interscope Records"
                  }
                ],
                "year": 2007,
                "artists": [
                  {
                    "join": "",
                    "name": "Nine Inch Nails",
                    "anv": "",
                    "tracks": "",
                    "role": "",
                    "resource_url": "https://api.discogs.com/artists/3857",
                    "id": 3857
                  }
                ],
                "resource_url": "https://api.discogs.com/releases/1867708",
                "id": 1867708
              },
              "resource_url": "https://api.discogs.com/users/example/wants/1867708",
              "id": 1867708
            },
            {
              "rating": 0,
              "basic_information": {
                "formats": [
                  {
                    "qty": "1",
                    "descriptions": ["Album"],
                    "name": "CDr"
                  }
                ],
                "thumb": "https://api-img.discogs.com/w1cVy7ppMYEDlqY9sjoAojC3MhQ=/fit-in/150x150/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-1675174-1236118359.jpeg.jpg",
                "cover_image": "https://api-img.discogs.com/w1cVy7ppMYEDlqY9sjoAojC3MhQ=/fit-in/347x352/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-1675174-1236118359.jpeg.jpg",
                "title": "Dawn Metropolis",
                "labels": [
                  {
                    "resource_url": "https://api.discogs.com/labels/141550",
                    "entity_type": "",
                    "catno": "NORM007",
                    "id": 141550,
                    "name": "Normative"
                  }
                ],
                "year": 2009,
                "artists": [
                  {
                    "join": "",
                    "name": "Anamanaguchi",
                    "anv": "",
                    "tracks": "",
                    "role": "",
                    "resource_url": "https://api.discogs.com/artists/667233",
                    "id": 667233
                  }
                ],
                "resource_url": "https://api.discogs.com/releases/1675174",
                "id": 1675174
              },
              "notes": "Sample notes.",
              "resource_url": "https://api.discogs.com/users/example/wants/1675174",
              "id": 1675174
            }
          ]
        }
        """.utf8
    )

    @Test func decodesOfficialResponseShape() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let wantList = try decoder.decode(WantList.self, from: mockJSON)

        #expect(wantList.pagination.page == 1)
        #expect(wantList.pagination.pages == 1)
        #expect(wantList.pagination.perPage == 50)
        #expect(wantList.pagination.items == 2)
        #expect(wantList.wants.count == 2)

        let first = try #require(wantList.wants.first)
        #expect(first.id == 1_867_708)
        #expect(first.rating == 4)
        #expect(first.notes == nil)
        #expect(first.basicInformation.title == "Year Zero")
        #expect(first.basicInformation.year == 2007)
        #expect(first.basicInformation.artists.first?.name == "Nine Inch Nails")
        #expect(first.basicInformation.labels.first?.catno == "B0008764-02")
        #expect(first.basicInformation.formats.first?.text == "Digipak")

        let second = try #require(wantList.wants.last)
        #expect(second.notes == "Sample notes.")
        #expect(second.basicInformation.title == "Dawn Metropolis")
        #expect(second.basicInformation.formats.first?.text == nil)
    }
}
