//
//  ReleaseAppleMusicLink.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseAppleMusicLink: View {

    let release: ReleaseDetailResponse

    @Environment(\.appleMusicCatalog) private var catalog
    @State private var url: URL?

    var body: some View {
        Group {
            if let url {
                Link(destination: url) {
                    Label("Apple Music", systemImage: "apple.logo")
                }
                .accessibilityLabel("Open in Apple Music")
            }
        }
        .task(id: release.id) {
            url = nil
            let found = await catalog.albumURL(for: release)
            guard !Task.isCancelled else { return }
            withAnimation {
                url = found
            }
        }
    }
}

#if DEBUG
#Preview {
    ReleaseAppleMusicLink(release: ReleaseFixtures.sampleRelease)
        .environment(\.appleMusicCatalog, PreviewAppleMusicCatalog())
}
#endif
