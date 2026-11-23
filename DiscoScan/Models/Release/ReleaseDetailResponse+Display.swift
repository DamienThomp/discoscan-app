//
//  ReleaseDetailResponse+Display.swift
//  DiscoScan
//

import Foundation

extension ReleaseDetailResponse {
    nonisolated var displayYear: Int? {
        year.displayYear
    }

    nonisolated var primaryArtistName: String {
        artists.first?.name ?? "n/a"
    }

    nonisolated var barcode: String? {
        identifiers.first(where: { $0.type == "Barcode" })?.value
    }

    nonisolated var primaryImageURL: URL? {
        images.first(where: { $0.type == "primary" })?.uri ?? thumb
    }

    nonisolated var formatSummary: String? {
        guard !formats.isEmpty else { return nil }
        return formats.map { format in
            ([format.name] + format.descriptions).joined(separator: ", ")
        }.joined(separator: " / ")
    }

    nonisolated var labelSummary: String? {
        guard let label = labels.first else { return nil }
        if label.catno.isEmpty {
            return label.name
        }
        return "\(label.name) — \(label.catno)"
    }

    nonisolated var genreStyleSummary: String? {
        let tags = genres + styles
        guard !tags.isEmpty else { return nil }
        return tags.joined(separator: ", ")
    }

    nonisolated var displayReleased: String? {
        releasedFormatted ?? released
    }
}

extension ReleaseDetailCommunity {
    nonisolated var summary: String {
        "\(have) have · \(want) want · \(rating.ratingSummary)"
    }
}

extension ReleaseDetailRating {
    nonisolated var ratingSummary: String {
        guard let average else {
            return "\(count) ratings"
        }
        let formattedAverage = average.formatted(.number.precision(.fractionLength(1)))
        return "\(formattedAverage) avg (\(count) ratings)"
    }
}
