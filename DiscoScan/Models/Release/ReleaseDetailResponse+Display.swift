//
//  ReleaseDetailResponse+Display.swift
//  DiscoScan
//

import Foundation

/// Display strings for `ReleaseDetailResponse`, callable from any isolation domain.
nonisolated enum ReleaseDetailDisplay {
    static func displayYear(for release: ReleaseDetailResponse) -> Int? {
        release.year.displayYear
    }

    static func primaryArtistName(for release: ReleaseDetailResponse) -> String {
        release.artists.first?.name ?? "n/a"
    }

    static func barcode(for release: ReleaseDetailResponse) -> String? {
        release.identifiers.first(where: { $0.type == "Barcode" })?.value
    }

    static func primaryImageURL(for release: ReleaseDetailResponse) -> URL? {
        release.images.first(where: { $0.type == "primary" })?.uri ?? release.thumb
    }

    static func formatSummary(for release: ReleaseDetailResponse) -> String? {
        guard !release.formats.isEmpty else { return nil }
        return release.formats.map { format in
            ([format.name] + format.descriptions).joined(separator: ", ")
        }.joined(separator: " / ")
    }

    static func labelSummary(for release: ReleaseDetailResponse) -> String? {
        guard let label = release.labels.first else { return nil }
        if label.catno.isEmpty {
            return label.name
        }
        return "\(label.name) — \(label.catno)"
    }

    static func genreStyleSummary(for release: ReleaseDetailResponse) -> String? {
        let tags = release.genres + release.styles
        guard !tags.isEmpty else { return nil }
        return tags.joined(separator: ", ")
    }

    static func displayReleased(for release: ReleaseDetailResponse) -> String? {
        release.releasedFormatted ?? release.released
    }
}

extension ReleaseDetailResponse {
    nonisolated var displayYear: Int? {
        ReleaseDetailDisplay.displayYear(for: self)
    }

    nonisolated var primaryArtistName: String {
        ReleaseDetailDisplay.primaryArtistName(for: self)
    }

    nonisolated var barcode: String? {
        ReleaseDetailDisplay.barcode(for: self)
    }

    nonisolated var primaryImageURL: URL? {
        ReleaseDetailDisplay.primaryImageURL(for: self)
    }

    nonisolated var formatSummary: String? {
        ReleaseDetailDisplay.formatSummary(for: self)
    }

    nonisolated var labelSummary: String? {
        ReleaseDetailDisplay.labelSummary(for: self)
    }

    nonisolated var genreStyleSummary: String? {
        ReleaseDetailDisplay.genreStyleSummary(for: self)
    }

    nonisolated var displayReleased: String? {
        ReleaseDetailDisplay.displayReleased(for: self)
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