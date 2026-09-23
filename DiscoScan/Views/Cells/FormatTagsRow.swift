//
//  FormatTagsRow.swift
//  DiscoScan
//

import SwiftUI

struct FormatTagsRow: View {
    let formats: [String]

    private var displayedFormats: [String] {
        Array(formats.prefix(2))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(displayedFormats.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                if index < displayedFormats.count - 1 {
                    Divider()
                        .frame(height: 8)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    FormatTagsRow(formats: ["Vinyl", "LP", "Album", "Stereo"])
}
#endif
