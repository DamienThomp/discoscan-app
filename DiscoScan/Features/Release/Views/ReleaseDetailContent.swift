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
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 8) {
            ReleaseArtworkView(
                url: release.primaryImageURL,
                size: .large,
                accessibilityLabel: "Album artwork for \(release.title)"
            )

            VStack(alignment: .center, spacing: 8) {
                Text(release.title)
                    .font(.title2.bold())

                Text(release.primaryArtistName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if let year = release.displayYear {
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
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(headerAccessibilityLabel)
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
                .accessibilityAddTraits(.isHeader)

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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(trackAccessibilityLabel(for: track))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tracklist")
    }

    private var communitySection: some View {
        let ratingSummary: String = {
            guard let average = release.community.rating.average else {
                return "\(release.community.rating.count) ratings"
            }
            let formattedAverage = average.formatted(.number.precision(.fractionLength(1)))
            return "\(formattedAverage) avg (\(release.community.rating.count) ratings)"
        }()
        return detailSection(
            title: "Community",
            value: "\(release.community.have) have · \(release.community.want) want · \(ratingSummary)"
        )
    }

    private var headerAccessibilityLabel: String {
        var components = [release.title, release.primaryArtistName]
        if let year = release.displayYear {
            components.append(String(year))
        }
        if let country = release.country {
            components.append(country)
        }
        if let released = release.releasedFormatted ?? release.released {
            components.append(released)
        }
        return components.joined(separator: ", ")
    }

    private func trackAccessibilityLabel(for track: ReleaseDetailTrack) -> String {
        if let duration = track.duration, !duration.isEmpty {
            return "\(track.position), \(track.title), \(duration)"
        }
        return "\(track.position), \(track.title)"
    }

    private func detailSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}
