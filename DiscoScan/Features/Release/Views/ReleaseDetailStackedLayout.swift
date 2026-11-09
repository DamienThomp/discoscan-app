//
//  ReleaseDetailStackedLayout.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailStackedLayout: View {

    let release: ReleaseDetailResponse

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.content) {
                    ReleaseDetailHeader(release: release)
                    ReleaseDetailSections(release: release)
                        .padding(.bottom, proxy.safeAreaInsets.bottom)
                        .background(.quaternary)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity)
    }
}
