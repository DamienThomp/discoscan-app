//
//  ReleaseDetailContent.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailContent: View {
    let release: ReleaseDetailResponse

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.content) {
                header
                metadataSection
                if let genreStyleSummary = release.genreStyleSummary {
                    DetailSectionView(title: "Genres & Styles", value: genreStyleSummary)
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
        VStack(alignment: .center, spacing: AppSpacing.metadata * 2) {
            ReleaseArtworkView(
                url: release.primaryImageURL,
                size: .large,
                accessibilityLabel: "Album artwork for \(release.title)"
            )

            VStack(alignment: .center, spacing: AppSpacing.metadata * 2) {
                Text(release.title)
                    .font(.title2.bold())

                Text(release.primaryArtistName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: AppSpacing.metadata * 2) {

                    if let year = release.displayYear {
                        Text(year, format: .number.grouping(.never))
                    }
                    if let country = release.country {
                        Text(country)
                    }
                    if let released = release.releasedFormatted ?? release.released {
                        Text(released)
                    }
                    if let lowestPrice = release.lowestPrice {
                        Text(lowestPrice, format: .currency(code: "USD"))
                    }
                }
                .appSecondaryMetadata()


            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(headerAccessibilityLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            if let formatSummary = release.formatSummary {
                DetailSectionView(title: "Format", value: formatSummary)
            }
            if let labelSummary = release.labelSummary {
                DetailSectionView(title: "Label", value: labelSummary)
            }
        }
    }

    private var tracklistSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.metadata * 2) {
            Text("Tracklist")
                .appSectionHeader()

            ForEach(Array(release.tracklist.enumerated()), id: \.offset) { _, track in
                TracklistRowView(
                    position: track.position,
                    title: track.title,
                    duration: track.duration
                )
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
        return DetailSectionView(
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
}
