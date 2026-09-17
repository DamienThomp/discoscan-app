//
//  ResourceContainerView.swift
//  DiscoScan
//

import SwiftUI

struct ResourceContainerView<T: Equatable & Sendable, Content: View>: View {

    let state: ResourceState<T>
    let retry: () async -> Void

    @ViewBuilder let content: (T) -> Content

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView()
            case .loaded(let value):
                content(value)
            case .failed(let message):
                ErrorView(message: message) {
                    Task { await retry() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
