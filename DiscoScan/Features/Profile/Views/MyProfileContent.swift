//
//  MyProfileContent.swift
//  DiscoScan
//

import SwiftUI

struct MyProfileContent: View {
    let profile: DiscogsUserProfile

    private let avatarSize: CGFloat = 120

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.content) {
                AvatarView(
                    url: profile.avatarImageURL,
                    size: avatarSize,
                    accessibilityLabel: "Profile photo for \(profile.displayName)"
                )

                VStack(spacing: AppSpacing.metadata) {
                    Text(profile.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("@\(profile.username)")
                        .appSecondaryMetadata()
                }

                if let location = profile.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .appSecondaryMetadata()
                }

                VStack(spacing: AppSpacing.section) {
                    LabeledContent("Collection", value: profile.displayCollectionCount)
                    LabeledContent("Member since", value: profile.displayRegisteredDate)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                if let bio = profile.profile, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, AppSpacing.screen)
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        MyProfileContent(profile: ProfileFixtures.sample)
    }
}
#endif
