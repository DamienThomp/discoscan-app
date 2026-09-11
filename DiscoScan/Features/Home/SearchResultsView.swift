//
//  SearchResultsView.swift
//  DiscoScan
//

import NetworkKit
import SwiftUI

struct SearchResultsView: View {
    @Environment(\.discogsClient) private var discogsClient

    let query: String

    @State private var results: [SearchResult] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Searching…")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Search Failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No releases matched \"\(query)\".")
                )
            } else {
                List(results) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.headline)
                        Text(result.type.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Results")
        .task(id: query) {
            await loadResults()
        }
    }

    private func loadResults() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await discogsClient.request(for: SearchEndpoint(query: query))
            results = response.results
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }
}
