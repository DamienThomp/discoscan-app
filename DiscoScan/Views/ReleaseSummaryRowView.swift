//
//  ReleaseSummaryRowView.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseSummaryRowView: View {
    let information: ReleaseBasicInformation

    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 50

    var body: some View {
        HStack {
            artwork

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

    @ViewBuilder
    private var artwork: some View {
        AsyncImage(url: information.listArtworkURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                ReleaseArtworkPlaceholder()
            case .empty:
                ReleaseArtworkPlaceholder(showProgress: true)
            @unknown default:
                ReleaseArtworkPlaceholder()
            }
        }
        .frame(width: imageSize, height: imageSize)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        if let year = information.year {
            return "\(information.title), \(information.primaryArtistName), \(year)"
        }
        return "\(information.title), \(information.primaryArtistName)"
    }
}

private struct ReleaseArtworkPlaceholder: View {
    var showProgress: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
            if showProgress {
                ProgressView()
            } else {
                Image(systemName: "opticaldisc")
                    .foregroundStyle(.tertiary)
            }
        }
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
