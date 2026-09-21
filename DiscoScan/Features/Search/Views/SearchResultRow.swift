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
            accessibilityLabel: "\(result.title), \(result.type)"
        ) {
            Text(result.type.capitalized)
                .appSecondaryMetadata()

            if let format = result.format {
                FormatTagsRow(formats: format)
            }
        }
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
                format: ["Vinyl", "LP", "Album", "Stereo"]
            )
        )
    }
}
#endif
