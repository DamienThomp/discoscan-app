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
        ZStack {
            switch state {
            case .idle, .loading:
                LoadingView()
            case .loaded(let value), .refreshing(let value):
                content(value).transition(.opacity)
            case .failed(let message):
                ErrorView(message: message) { Task { await retry() } }.transition(.opacity)
            }
        }
        .animation(.default, value: state)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
