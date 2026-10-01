//
//  CollectionSyncBanner.swift
//  DiscoScan
//

import SwiftUI

struct CollectionSyncBanner: View {
    let phase: CollectionSyncPhase
    var onRetry: (() async -> Void)?

    var body: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView("Checking collection…")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.row)
                .padding(.vertical, AppSpacing.compact)
        case .syncing(let synced, let total):
            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                ProgressView("Syncing collection…", value: Double(synced), total: Double(total))
                Text("\(synced) of \(total)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.row)
            .padding(.vertical, AppSpacing.compact)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Syncing collection, \(synced) of \(total)")
        case .failed(let message):
            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let onRetry {
                    Button("Retry") {
                        Task { await onRetry() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.row)
            .padding(.vertical, AppSpacing.compact)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Collection sync failed, \(message)")
        }
    }
}

#if DEBUG
#Preview("Syncing") {
    CollectionSyncBanner(phase: .syncing(synced: 450, total: 2100))
        .preferredColorScheme(.dark)
}

#Preview("Checking") {
    CollectionSyncBanner(phase: .checking)
        .preferredColorScheme(.dark)
}

#Preview("Failed") {
    CollectionSyncBanner(phase: .failed("Couldn't sync your collection.")) {}
        .preferredColorScheme(.dark)
}
#endif
