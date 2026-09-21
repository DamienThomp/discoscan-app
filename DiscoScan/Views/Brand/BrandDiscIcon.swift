//
//  BrandDiscIcon.swift
//  DiscoScan
//

import SwiftUI

struct BrandDiscIcon: View {
    var isAnimating: Bool = false

    var body: some View {
        Image(systemName: "opticaldisc.fill")
            .font(.system(size: AppIconSize.brandDisc))
            .foregroundStyle(.tint)
            .symbolEffect(.rotate, options: .speed(10), isActive: isAnimating)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Static") {
    BrandDiscIcon()
}

#Preview("Animating") {
    BrandDiscIcon(isAnimating: true)
}
#endif
