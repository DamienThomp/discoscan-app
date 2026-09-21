//
//  LoadingView.swift
//  DiscoScan
//

import SwiftUI

struct LoadingView: View {

    var text: String = "Loading…"

    @State private var isAnimating: Bool = true

    var body: some View {
        VStack(spacing: AppSpacing.metadata * 2) {
            BrandDiscIcon(isAnimating: isAnimating)
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
