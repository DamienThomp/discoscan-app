//
//  PaginationTrigger.swift
//  DiscoScan
//

import SwiftUI

struct PaginationTrigger: View {
    let loadMore: () async -> Void

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .accessibilityLabel("Loading more")
            .task {
                await loadMore()
            }
    }
}
