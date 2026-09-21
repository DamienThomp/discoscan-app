//
//  PaginatedReleaseListView.swift
//  DiscoScan
//

import SwiftUI

struct PaginatedReleaseListView<Item: Identifiable>: View {
    let items: [Item]
    let emptyState: AnimatedEmptyStateView.Configuration
    let releaseID: (Item) -> Int
    let basicInformation: (Item) -> ReleaseBasicInformation
    let canLoadMore: Bool
    let loadMore: () async -> Void
    let delete: (Item) async -> Void

    var body: some View {
        if items.isEmpty {
            AnimatedEmptyStateView(configuration: emptyState)
                .transition(.opacity)
        } else {
            List {
                ForEach(items) { item in
                    NavigationLink(value: AppRoute.releaseDetail(id: releaseID(item))) {
                        ReleaseSummaryRowView(information: basicInformation(item))
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await delete(item)
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }

                if canLoadMore {
                    PaginationTrigger {
                        await loadMore()
                    }
                }
            }
            .transition(.opacity)
        }
    }
}
