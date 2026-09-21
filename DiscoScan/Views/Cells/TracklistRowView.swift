//
//  TracklistRowView.swift
//  DiscoScan
//

import SwiftUI

struct TracklistRowView: View {
    let position: String
    let title: String
    let duration: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.row) {
            Text(position)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            Text(title)
                .font(.body)

            Spacer(minLength: AppSpacing.row)

            if let duration, !duration.isEmpty {
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let duration, !duration.isEmpty {
            return "\(position), \(title), \(duration)"
        }
        return "\(position), \(title)"
    }
}

#if DEBUG
#Preview {
    TracklistRowView(position: "A1", title: "Closer", duration: "6:06")
        .padding()
}
#endif
