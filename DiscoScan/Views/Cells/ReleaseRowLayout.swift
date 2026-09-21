//
//  ReleaseRowLayout.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseRowLayout<Metadata: View>: View {
    let artworkURL: URL?
    let title: String
    let accessibilityLabel: String
    var accessibilityHint: String = "Shows release details"
    @ViewBuilder let metadata: () -> Metadata

    var body: some View {
        HStack(spacing: AppSpacing.row) {
            ReleaseArtworkView(url: artworkURL, size: .medium)

            VStack(alignment: .leading, spacing: AppSpacing.metadata) {
                Text(title)
                    .appReleaseTitle()
                    .lineLimit(2)

                metadata()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

#if DEBUG
#Preview {
    List {
        ReleaseRowLayout(
            artworkURL: nil,
            title: "Year Zero",
            accessibilityLabel: "Year Zero, Nine Inch Nails, 2007"
        ) {
            Group {
                Text("Nine Inch Nails")
                Text(2007, format: .number.grouping(.never))
            }
            .appSecondaryMetadata()
        }
    }
}
#endif
