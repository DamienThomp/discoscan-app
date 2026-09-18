//
//  SearchResultRow.swift
//  DiscoScan
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack {
            ReleaseArtworkView(url: result.thumb, size: .thumb)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(result.type.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.title), \(result.type)")
        .accessibilityHint("Shows release details")
    }
}

#if DEBUG
#Preview {
    List {
        SearchResultRow(
            result: SearchResult(
                id: 249_504,
                type: "release",
                title: "Rick Astley - Never Gonna Give You Up"
            )
        )
    }
}
#endif
