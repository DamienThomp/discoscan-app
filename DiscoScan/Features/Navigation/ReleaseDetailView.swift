//
//  ReleaseDetailView.swift
//  DiscoScan
//

import SwiftUI

struct ReleaseDetailView: View {
    let releaseID: Int

    var body: some View {
        ContentUnavailableView(
            "Release \(releaseID)",
            systemImage: "opticaldisc",
            description: Text("Release detail navigation is wired and ready for a dedicated endpoint.")
        )
        .navigationTitle("Release")
    }
}
