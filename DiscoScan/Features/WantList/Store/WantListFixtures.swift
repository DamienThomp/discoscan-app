//
//  WantListFixtures.swift
//  DiscoScan
//

import Foundation

enum WantListFixtures {
    static let samplePagination = SearchPagination(page: 1, pages: 2, perPage: 50, items: 60)

    static let sampleWants: [WantListItem] = [
        WantListItem(
            id: 1_867_708,
            rating: 4,
            notes: nil,
            resourceURL: URL(string: "https://api.discogs.com/users/example/wants/1867708"),
            basicInformation: ReleaseBasicInformation(
                id: 1_867_708,
                title: "Year Zero",
                year: 2007,
                thumb: nil,
                coverImage: nil,
                resourceURL: URL(string: "https://api.discogs.com/releases/1867708"),
                artists: [DiscogsArtist(id: 3857, name: "Nine Inch Nails")],
                labels: [DiscogsLabel(id: 2311, name: "Interscope Records", catno: "B0008764-02")],
                formats: [DiscogsFormat(name: "CD", qty: "1", text: "Digipak", descriptions: ["Album"])]
            )
        ),
        WantListItem(
            id: 1_675_174,
            rating: 0,
            notes: "Sample notes.",
            resourceURL: URL(string: "https://api.discogs.com/users/example/wants/1675174"),
            basicInformation: ReleaseBasicInformation(
                id: 1_675_174,
                title: "Dawn Metropolis",
                year: 2009,
                thumb: nil,
                coverImage: nil,
                resourceURL: URL(string: "https://api.discogs.com/releases/1675174"),
                artists: [DiscogsArtist(id: 667_233, name: "Anamanaguchi")],
                labels: [DiscogsLabel(id: 141_550, name: "Normative", catno: "NORM007")],
                formats: [DiscogsFormat(name: "CDr", qty: "1", text: nil, descriptions: ["Album"])]
            )
        )
    ]

    static let sampleResponse = WantListResponse(
        pagination: samplePagination,
        wants: sampleWants
    )
}
