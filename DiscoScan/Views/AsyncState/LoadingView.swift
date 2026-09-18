//
//  LoadingView.swift
//  DiscoScan
//

import SwiftUI

struct LoadingView: View {

    @State private var isAnimating: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "opticaldisc.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolEffect(.rotate, options: .speed(10), isActive: isAnimating)
            Text("Loading…")
                .font(.title2)

        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
