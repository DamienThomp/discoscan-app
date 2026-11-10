//
//  ReleaseDetailContent.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailContent: View {

    let release: ReleaseDetailResponse

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { proxy in
            let useColumnLayout = horizontalSizeClass == .regular
                && proxy.size.width > proxy.size.height

            if useColumnLayout {
                ReleaseDetailColumnLayout(release: release)
            } else {
                ReleaseDetailStackedLayout(release: release)
            }
        }
    }
}
