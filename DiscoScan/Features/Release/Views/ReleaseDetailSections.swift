//
//  ReleaseDetailSections.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailSections: View {

    let release: ReleaseDetailResponse

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.row) {
            metadataSection
            if let genreStyleSummary = release.genreStyleSummary {
                DetailSectionView(title: "Genres & Styles", value: genreStyleSummary)
            }
            if !release.tracklist.isEmpty {
                ReleaseTracklistSection(tracks: release.tracklist)
            }
            DetailSectionView(title: "Community", value: release.community.summary)
        }
        .padding(AppSpacing.content)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            if let formatSummary = release.formatSummary {
                DetailSectionView(title: "Format", value: formatSummary)
            }
            if let labelSummary = release.labelSummary {
                DetailSectionView(title: "Label", value: labelSummary)
            }
        }
    }
}
