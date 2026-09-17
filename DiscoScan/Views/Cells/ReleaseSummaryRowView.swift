//
//  ReleaseSummaryRowView.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseSummaryRowView: View {
    let information: ReleaseBasicInformation

    var body: some View {
        HStack {
            ReleaseArtworkView(url: information.listArtworkURL, size: .thumb)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(information.title)
                    .font(.headline.bold())
                HStack {
                    Text(information.primaryArtistName)
                    if let year = information.year {
                        Text(year, format: .number.grouping(.never))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let year = information.year {
            return "\(information.title), \(information.primaryArtistName), \(year)"
        }
        return "\(information.title), \(information.primaryArtistName)"
    }
}

#if DEBUG
private enum ReleaseSummaryRowPreviewFixtures {
    static let sample = ReleaseBasicInformation(
        id: 1_867_708,
        title: "Year Zero",
        year: 2007,
        thumb: URL(string: "https://api-img.discogs.com/example-thumb.jpg"),
        coverImage: nil,
        resourceURL: URL(string: "https://api.discogs.com/releases/1867708"),
        artists: [DiscogsArtist(id: 3857, name: "Nine Inch Nails")],
        labels: [],
        formats: []
    )

    static let withoutArtwork = ReleaseBasicInformation(
        id: 100,
        title: "Test Release",
        year: 2020,
        thumb: nil,
        coverImage: nil,
        resourceURL: nil,
        artists: [DiscogsArtist(id: 1, name: "Preview Artist")],
        labels: [],
        formats: []
    )
}

#Preview("Default") {
    List {
        ReleaseSummaryRowView(information: ReleaseSummaryRowPreviewFixtures.sample)
    }
}

#Preview("No Artwork") {
    List {
        ReleaseSummaryRowView(information: ReleaseSummaryRowPreviewFixtures.withoutArtwork)
    }
}
#endif
