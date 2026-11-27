//
//  LoadingView.swift
//  DiscoScan
//

import SwiftUI

struct LoadingView: View {

    var text: String = "Loading…"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating: Bool = true

    var body: some View {
        VStack(spacing: AppSpacing.compact) {
            BrandDiscIcon(isAnimating: isAnimating && !reduceMotion)
            Text(text)
                .font(.title2)

        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    LoadingView()
}
#endif
