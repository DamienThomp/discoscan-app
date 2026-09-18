//
//  ReleaseDetailResponseTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct ReleaseDetailResponseTests {
    private let mockJSON = Data(
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
            "thumb": "https://api-img.discogs.com/kAXVhuZuh_uat5NNr50zMjN7lho=/fit-in/300x300/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg",
            "community": {
                "contributors": [
                    {
                        "resource_url": "https://api.discogs.com/users/memory",
                        "username": "memory"
                    },
                    {
                        "resource_url": "https://api.discogs.com/users/_80_",
                        "username": "_80_"
                    }
                ],
                "data_quality": "Correct",
                "have": 252,
                "rating": {
                    "average": 3.42,
                    "count": 45
                },
                "status": "Accepted",
                "submitter": {
                    "resource_url": "https://api.discogs.com/users/memory",
                    "username": "memory"
                },
                "want": 42
            },
            "companies": [
                {
                    "catno": "",
                    "entity_type": "13",
                    "entity_type_name": "Phonographic Copyright (p)",
                    "id": 82835,
                    "name": "BMG Records (UK) Ltd.",
                    "resource_url": "https://api.discogs.com/labels/82835"
                }
            ],
            "country": "UK",
            "date_added": "2004-04-30T08:10:05-07:00",
            "date_changed": "2012-12-03T02:50:12-07:00",
            "estimated_weight": 60,
            "extraartists": [
                {
                    "anv": "Stock / Aitken / Waterman",
                    "id": 20942,
                    "join": "",
                    "name": "Stock, Aitken & Waterman",
                    "resource_url": "https://api.discogs.com/artists/20942",
                    "role": "Producer, Written-By",
                    "tracks": ""
                }
            ],
            "format_quantity": 1,
            "formats": [
                {
                    "descriptions": [
                        "7\\"",
                        "Single",
                        "45 RPM"
                    ],
                    "name": "Vinyl",
                    "qty": "1"
                }
            ],
            "genres": [
                "Electronic",
                "Pop"
            ],
            "identifiers": [
                {
                    "type": "Barcode",
                    "value": "5012394144777"
                }
            ],
            "images": [
                {
                    "height": 600,
                    "resource_url": "https://api-img.discogs.com/z_u8yqxvDcwVnR4tX2HLNLaQO2Y=/fit-in/600x600/filters:strip_icc():format(jpeg):mode_rgb():quality(96)/discogs-images/R-249504-1334592212.jpeg.jpg",
                    "type": "primary",
                    "uri": "https://api-img.discogs.com/z_u8yqxvDcwVnR4tX2HLNLaQO2Y=/fit-in/600x600/filters:strip_icc():format(jpeg):mode_rgb():quality(96)/discogs-images/R-249504-1334592212.jpeg.jpg",
                    "uri150": "https://api-img.discogs.com/0ZYgPR4X2HdUKA_jkhPJF4SN5mM=/fit-in/150x150/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg",
                    "width": 600
                }
            ],
            "labels": [
                {
                    "catno": "PB 41447",
                    "entity_type": "1",
                    "id": 895,
                    "name": "RCA",
                    "resource_url": "https://api.discogs.com/labels/895"
                }
            ],
            "lowest_price": 0.63,
            "master_id": 96559,
            "master_url": "https://api.discogs.com/masters/96559",
            "notes": "UK Release has a black label.",
            "num_for_sale": 58,
            "released": "1987",
            "released_formatted": "1987",
            "resource_url": "https://api.discogs.com/releases/249504",
            "series": [],
            "status": "Accepted",
            "styles": [
                "Synth-pop"
            ],
            "tracklist": [
                {
                    "duration": "3:32",
                    "position": "A",
                    "title": "Never Gonna Give You Up",
                    "type_": "track"
                },
                {
                    "duration": "3:30",
                    "position": "B",
                    "title": "Never Gonna Give You Up (Instrumental)",
                    "type_": "track"
                }
            ],
            "uri": "https://www.discogs.com/Rick-Astley-Never-Gonna-Give-You-Up/release/249504",
            "videos": [
                {
                    "description": "Rick Astley - Never Gonna Give You Up (Extended Version)",
                    "duration": 330,
                    "embed": true,
                    "title": "Rick Astley - Never Gonna Give You Up (Extended Version)",
                    "uri": "https://www.youtube.com/watch?v=te2jJncBVG4"
                }
            ],
            "year": 1987
        }
        """.utf8
    )

    @Test func decodesOfficialResponseShape() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let release = try decoder.decode(ReleaseDetailResponse.self, from: mockJSON)

        #expect(release.id == 249504)
        #expect(release.title == "Never Gonna Give You Up")
        #expect(release.year == 1987)
        #expect(release.country == "UK")
        #expect(release.artists.first?.name == "Rick Astley")
        #expect(release.community.have == 252)
        #expect(release.community.want == 42)
        #expect(release.community.rating.average == 3.42)
        #expect(release.companies.first?.entityTypeName == "Phonographic Copyright (p)")
        #expect(release.formats.first?.name == "Vinyl")
        #expect(release.formats.first?.descriptions == ["7\"", "Single", "45 RPM"])
        #expect(release.identifiers.first?.value == "5012394144777")
        #expect(release.labels.first?.catno == "PB 41447")
        #expect(release.lowestPrice == 0.63)
        #expect(release.numForSale == 58)
        #expect(release.tracklist.count == 2)
        #expect(release.tracklist.first?.type == "track")
        #expect(release.tracklist.last?.position == "B")
        #expect(release.videos.first?.duration == 330)
        #expect(release.series.isEmpty)
    }
}
