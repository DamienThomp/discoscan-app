//
//  FormatTagsRow.swift
//  DiscoScan
//

import SwiftUI

struct FormatTagsRow: View {
    let formats: [String]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(formats.enumerated(), id: \.offset) { index, item in
                Text(item)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                if index < formats.count - 1 {
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
