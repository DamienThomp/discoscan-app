//
//  ReleaseDetailColumnLayout.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailColumnLayout: View {

    let release: ReleaseDetailResponse

    var body: some View {
        HStack(spacing: 0) {
            ReleaseDetailHeader(release: release)
                .padding(.vertical, AppSpacing.content)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ScrollView {
                ReleaseDetailSections(release: release)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.quaternary)
        }
    }
}

#if DEBUG
#Preview {
    ReleaseDetailColumnLayout(release: ReleaseFixtures.sampleRelease)
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.appleMusicCatalog, PreviewAppleMusicCatalog())
}
#endif
