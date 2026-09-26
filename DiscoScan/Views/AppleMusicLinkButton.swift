//
//  AppleMusicLinkButton.swift
//  DiscoScan
//

import SwiftUI

struct AppleMusicLinkButton: View {

    let url: URL?

    var body: some View {
        Group {
            if let url {
                Link(destination: url) {
                    Label("Apple Music", systemImage: "apple.logo")
                }
                .accessibilityLabel("Open in Apple Music")
            }
        }
    }
}
