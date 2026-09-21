//
//  AvatarView.swift
//  DiscoScan
//

import SwiftUI

struct AvatarView: View {
    let url: URL?
    var size: CGFloat = 120
    let accessibilityLabel: String

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(.quaternary)

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.55))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
#Preview("With URL") {
    AvatarView(
        url: URL(string: "https://example.com/avatar.jpg"),
        accessibilityLabel: "Profile photo"
    )
}

#Preview("Placeholder") {
    AvatarView(url: nil, accessibilityLabel: "Profile photo")
}
#endif
