//
//  ReleaseTracklistSection.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseTracklistSection: View {

    let tracks: [ReleaseDetailTrack]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            Text("Tracklist")
                .appSectionHeader()

            ForEach(tracks.enumerated(), id: \.offset) { _, track in
                TracklistRowView(
                    position: track.position,
                    title: track.title,
                    duration: track.duration
                )

                Divider()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tracklist")
    }
}
