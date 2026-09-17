//
//  ReleaseDetailContent.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailContent: View {
    let release: ReleaseDetailResponse

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                metadataSection
                if let genreStyleSummary = release.genreStyleSummary {
                    detailSection(title: "Genres & Styles", value: genreStyleSummary)
                }
                if !release.tracklist.isEmpty {
                    tracklistSection
                }
                communitySection
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 8) {
            ReleaseArtworkView(url: release.primaryImageURL, size: .large)

            Text(release.title)
                .font(.title2.bold())

            Text(release.primaryArtistName)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if let year = release.year {
                    Text(year, format: .number.grouping(.never))
                }
                if let country = release.country {
                    Text(country)
                }
                if let released = release.releasedFormatted ?? release.released {
                    Text(released)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let formatSummary = release.formatSummary {
                detailSection(title: "Format", value: formatSummary)
            }
            if let labelSummary = release.labelSummary {
                detailSection(title: "Label", value: labelSummary)
            }
        }
    }

    private var tracklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracklist")
                .font(.headline)

            ForEach(Array(release.tracklist.enumerated()), id: \.offset) { _, track in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(track.position)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)

                    Text(track.title)
                        .font(.body)

                    Spacer(minLength: 8)

                    if let duration = track.duration, !duration.isEmpty {
                        Text(duration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var communitySection: some View {
        let averageRating = release.community.rating.average.formatted(
            .number.precision(.fractionLength(1))
        )
        return detailSection(
            title: "Community",
            value: "\(release.community.have) have · \(release.community.want) want · \(averageRating) avg (\(release.community.rating.count) ratings)"
        )
    }

    private func detailSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
