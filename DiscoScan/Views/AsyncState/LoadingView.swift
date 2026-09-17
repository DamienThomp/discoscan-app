//
//  LoadingView.swift
//  DiscoScan
//

import SwiftUI

struct LoadingView: View {

    var body: some View {
        ProgressView("Loading…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
