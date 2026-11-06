//
//  ReleaseArtworkView.swift
//  DiscoScan
//

import SwiftUI

enum ReleaseArtworkSize {
    case thumb
    case medium
    case large

    var baseDimension: CGFloat {
        switch self {
        case .thumb: 80
        case .medium: 120
        case .large: 280
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .thumb: 8
        case .medium: 10
        case .large: 12
        }
    }

    func dimension(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        let base = baseDimension
        guard horizontalSizeClass == .regular else { return base }
        switch self {
        case .thumb:
            return base
        case .medium:
            return base * 1.25
        case .large:
            return min(base * 1.15, 360)
        }
    }

    var usesHeroLayout: Bool {
        self == .large
    }

    var hidesFromAccessibilityByDefault: Bool {
        self == .thumb
    }
}

struct ReleaseArtworkView: View {

    let url: URL?
    let size: ReleaseArtworkSize
    var accessibilityLabel: String? = nil
    var hidesFromAccessibility: Bool? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .body) private var dynamicTypeScale: CGFloat = ReleaseArtworkSize.thumb.baseDimension

    private var shouldHideFromAccessibility: Bool {
        hidesFromAccessibility ?? size.hidesFromAccessibilityByDefault
    }

    private var dimension: CGFloat {
        let deviceAdjusted = size.dimension(for: horizontalSizeClass)
        let scale = dynamicTypeScale / ReleaseArtworkSize.thumb.baseDimension
        return deviceAdjusted * scale
    }

    var body: some View {
        artworkImage
            .accessibilityHidden(shouldHideFromAccessibility)
            .accessibilityLabel(accessibilityLabel ?? "")
    }

    private var artworkImage: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder(showProgress: false)
            case .empty:
                placeholder(showProgress: true)
            @unknown default:
                placeholder(showProgress: false)
            }
        }
        .modifier(ArtworkFrameModifier(size: size, dimension: dimension))
        .modifier(ArtworkURLSessionModifier())
    }

    private func placeholder(showProgress: Bool) -> some View {
        ReleaseArtworkPlaceholder(
            cornerRadius: size.cornerRadius,
            showProgress: showProgress
        )
    }
}

private struct ArtworkFrameModifier: ViewModifier {
    let size: ReleaseArtworkSize
    let dimension: CGFloat

    func body(content: Content) -> some View {
        if size.usesHeroLayout {
            content
                .frame(maxWidth: dimension, maxHeight: dimension)
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                .frame(maxWidth: .infinity)
        } else {
            content
                .frame(width: dimension, height: dimension)
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        }
    }
}

private struct ReleaseArtworkPlaceholder: View {
    let cornerRadius: CGFloat
    var showProgress: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.quaternary)
                .aspectRatio(1, contentMode: .fit)

            if showProgress {
                ProgressView()
            } else {
                Image(systemName: "opticaldisc")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct ArtworkURLSessionModifier: ViewModifier {

    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
        return URLSession(configuration: config)
    }()

    func body(content: Content) -> some View {
        if #available(iOS 27, *) {
            content.asyncImageURLSession(Self.session)
        } else {
            content
        }
    }
}

#if DEBUG
#Preview("Sizes") {
    VStack(spacing: 24) {
        ReleaseArtworkView(url: nil, size: .thumb)
        ReleaseArtworkView(url: nil, size: .medium)
        ReleaseArtworkView(url: nil, size: .large, accessibilityLabel: "Album artwork")
    }
    .padding()
}
#endif
