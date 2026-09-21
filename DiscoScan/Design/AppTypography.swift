//
//  AppTypography.swift
//  DiscoScan
//

import SwiftUI

extension View {
    func appReleaseTitle() -> some View {
        font(.headline)
    }

    func appSecondaryMetadata() -> some View {
        font(.subheadline)
            .foregroundStyle(.secondary)
    }

    func appSectionHeader() -> some View {
        font(.headline)
            .accessibilityAddTraits(.isHeader)
    }

    func appFootnoteHint(multilineTextAlignment: TextAlignment = .center) -> some View {
        font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(multilineTextAlignment)
    }
}
