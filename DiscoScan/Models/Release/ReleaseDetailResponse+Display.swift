//
//  ReleaseDetailResponse+Display.swift
//  DiscoScan
//

import Foundation

extension ReleaseDetailResponse {
    var displayYear: Int? {
        year.displayYear
    }

    var primaryArtistName: String {
        artists.first?.name ?? "n/a"
    }

    var barcode: String? {
        identifiers.first(where: { $0.type == "Barcode" })?.value
    }

    var primaryImageURL: URL? {
        images.first(where: { $0.type == "primary" })?.uri ?? thumb
    }

    var formatSummary: String? {
        guard !formats.isEmpty else { return nil }
        return formats.map { format in
            ([format.name] + format.descriptions).joined(separator: ", ")
        }.joined(separator: " / ")
    }

    var labelSummary: String? {
        guard let label = labels.first else { return nil }
        if label.catno.isEmpty {
            return label.name
        }
        return "\(label.name) — \(label.catno)"
    }

    var genreStyleSummary: String? {
        let tags = genres + styles
        guard !tags.isEmpty else { return nil }
        return tags.joined(separator: ", ")
    }

    var displayReleased: String? {
        releasedFormatted ?? released
    }
}

extension ReleaseDetailCommunity {
    var summary: String {
        "\(have) have · \(want) want · \(rating.ratingSummary)"
    }
}

extension ReleaseDetailRating {
    var ratingSummary: String {
        guard let average else {
            return "\(count) ratings"
        }
        let formattedAverage = average.formatted(.number.precision(.fractionLength(1)))
        return "\(formattedAverage) avg (\(count) ratings)"
    }
}
