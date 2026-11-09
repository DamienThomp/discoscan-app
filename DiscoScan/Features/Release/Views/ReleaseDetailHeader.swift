//
//  ReleaseDetailHeader.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailHeader: View {

    let release: ReleaseDetailResponse

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.compact) {
            ReleaseArtworkView(
                url: release.primaryImageURL,
                size: .large,
                accessibilityLabel: "Album artwork for \(release.title)"
            )

            VStack(alignment: .center, spacing: AppSpacing.compact) {

                Group {
                    Text(release.title)
                        .font(.title2.bold())
                        .lineLimit(3)

                    Text(release.primaryArtistName)
                        .font(.headline)
                        .foregroundStyle(.tint)
                        .lineLimit(2)
                }
                .multilineTextAlignment(.center)

                HStack(spacing: AppSpacing.compact) {
                    if let country = release.country {
                        Text(country)
                    }
                    if let released = release.displayReleased {
                        Text(released)
                    }
                    if let lowestPrice = release.lowestPrice {
                        Text(lowestPrice, format: .currency(code: CurrencyAbbreviations.cad.rawValue))
                    }
                }
                .appSecondaryMetadata()
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)

            ReleaseAppleMusicLink(release: release)
                .padding(.top, AppSpacing.compact)
        }
        .padding(.horizontal, AppSpacing.content)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityLabel: String {
        var components = [release.title, release.primaryArtistName]
        if let year = release.displayYear {
            components.append(String(year))
        }
        if let country = release.country {
            components.append(country)
        }
        if let released = release.displayReleased {
            components.append(released)
        }
        return components.joined(separator: ", ")
    }
}
