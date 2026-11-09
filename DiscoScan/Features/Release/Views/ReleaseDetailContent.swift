//
//  ReleaseDetailContent.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailContent: View {

    let release: ReleaseDetailResponse

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            ReleaseDetailColumnLayout(release: release)
        } else {
            ReleaseDetailStackedLayout(release: release)
        }
    }
}
