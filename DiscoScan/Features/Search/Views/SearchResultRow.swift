//
//  SearchResultRow.swift
//  DiscoScan
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 16) {
            ReleaseArtworkView(url: result.thumb, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(result.type.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let format = result.format {
                        HStack {
                            ForEach(format.enumerated(), id: \.offset) { index, item in
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if index < format.count - 1 {
                                    Divider()
                                        .frame(height: 8)
                                }
                            }
                        }
                    }

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
                title: "Rick Astley - Never Gonna Give You Up",
                format: ["Vinyl", "LP", "Album", "Stereo"]
            )
        )
    }
}
#endif
