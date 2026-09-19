//
//  ResourceContainerView.swift
//  DiscoScan
//

import SwiftUI

struct ResourceContainerView<T: Equatable & Sendable, Content: View>: View {

    let state: ResourceState<T>
    let retry: () async -> Void

    @ViewBuilder let content: (T) -> Content

    @State private var showLoader = false

    private var isWaitingForContent: Bool {
        switch state {
        case .idle, .loading: true
        default: false
        }
    }

    var body: some View {
        ZStack {
            switch state {
            case .idle, .loading:
                if showLoader {
                    LoadingView()
                }
            case .loaded(let value), .refreshing(let value):
                content(value).transition(.opacity)
            case .failed(let message):
                ErrorView(message: message) { Task { await retry() } }.transition(.opacity)
            }
        }
        .animation(.default, value: state)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: isWaitingForContent) {
            showLoader = false
            guard isWaitingForContent else { return }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            showLoader = true
        }
    }
}
