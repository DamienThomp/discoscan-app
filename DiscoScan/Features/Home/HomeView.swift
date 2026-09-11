//
//  HomeView.swift
//  DiscoScan
//

import SwiftUI

struct HomeView: View {
    @Environment(AuthSession.self) private var authSession
    @Environment(AppRouter.self) private var router
    @State private var searchQuery = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if case .authenticated(let identity) = authSession.state {
                Text("Signed in as \(identity.username)")
                    .font(.headline)

                if let consumerName = identity.consumerName {
                    Text(consumerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                TextField("Search Discogs", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Search") {
                    let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    router.navigate(to: .searchResults(query: trimmed))
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("DiscoScan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Log Out", role: .destructive) {
                    Task {
                        await authSession.logout()
                        router.popToRoot()
                    }
                }
            }
        }
    }
}
