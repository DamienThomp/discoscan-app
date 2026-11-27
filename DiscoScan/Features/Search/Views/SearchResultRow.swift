//
//  SearchResultRow.swift
//  DiscoScan
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        ReleaseRowLayout(
            artworkURL: result.thumb,
            title: result.title,
            accessibilityLabel: accessibilityLabel
        ) {

            Group {

                if let country = result.country {
                    Text(country)
                        .font(.caption2)
                }

                HStack {
                    Text(result.type.capitalized)

                    if let year = result.year {
                        Text(year)
                    }
                }.appSecondaryMetadata()

                if let format = result.format {
                    FormatTagsRow(formats: format)
                }
            }
        }
    }

    private var accessibilityLabel: String {
        var components = [result.title, result.type.capitalized]
        if let country = result.country, !country.isEmpty {
            components.append(country)
        }
        if let year = result.year, !year.isEmpty {
            components.append(year)
        }
        if let formats = result.format?.prefix(2), !formats.isEmpty {
            components.append(formats.joined(separator: ", "))
        }
        return components.joined(separator: ", ")
    }
}

#if DEBUG
#Preview {
    List {
        SearchResultRow(
            result: SearchResult(
                id: 249_504,
                type: "release",
                title: "Rick Astley - Never Gonna Give You Up",
                format: ["Vinyl", "LP", "Album", "Stereo"],
                country: "United Kingdom",
                year: "1984"
            )
        )
    }
}
#endif
