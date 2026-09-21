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
            VStack(spacing: 20) {
                avatarView

                VStack(spacing: 4) {
                    Text(profile.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let location = profile.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
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
            .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let url = profile.avatarImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        avatarPlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .accessibilityLabel("Profile photo for \(profile.displayName)")
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(.quaternary)

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: avatarSize * 0.55))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
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
