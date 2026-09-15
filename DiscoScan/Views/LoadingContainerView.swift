//
//  LoadingContainerView.swift
//  DiscoScan
//

import SwiftUI

enum LoadingState<T>: Equatable where T: Equatable {

    case loading
    case success(T)
    case failed(String)
}

struct LoadingContainerView<T: Sendable & Equatable, Content: View>: View {

    let loadingAction: @Sendable () async throws -> T

    @ViewBuilder let content: (T) -> Content

    private let reloadIdentity: AnyHashable?

    @State private var loadingState: LoadingState<T> = .loading
    @State private var fetchAttempt = 0

    init(
        loadingAction: @escaping @Sendable () async throws -> T,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.reloadIdentity = nil
        self.loadingAction = loadingAction
        self.content = content
    }

    init<ID: Hashable>(
        id: ID,
        loadingAction: @escaping @Sendable () async throws -> T,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.reloadIdentity = AnyHashable(id)
        self.loadingAction = loadingAction
        self.content = content
    }

    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                LoadingView()
            case .success(let response):
                content(response)
            case .failed(let message):
                ErrorView(message: message) {
                    retry()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: taskTrigger) {
            await fetchData()
        }
    }

    private var taskTrigger: TaskTrigger {
        TaskTrigger(identity: reloadIdentity, attempt: fetchAttempt)
    }

    private func retry() {
        loadingState = .loading
        fetchAttempt += 1
    }

    private func fetchData() async {
        do {
            let response = try await loadingAction()
            guard !Task.isCancelled else { return }
            loadingState = .success(response)
        } catch {
            guard !Task.isCancelled else { return }
            loadingState = .failed(error.localizedDescription)
        }
    }
}

private struct TaskTrigger: Equatable {

    let identity: AnyHashable?
    let attempt: Int
}

#Preview {
    LoadingContainerView {
        try await Task.sleep(for: .seconds(1))
        return ["Kind of Blue", "Blue Train"]
    } content: { albums in
        List(albums, id: \.self) { album in
            Text(album)
        }
    }
}
