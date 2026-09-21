//
//  MyProfileView.swift
//  DiscoScan
//

import SwiftUI

struct MyProfileView: View {
    @Environment(AuthSession.self) private var authSession

    var body: some View {
        Group {
            if case .authenticated(let identity) = authSession.state {
                ContentUnavailableView(
                    identity.username,
                    systemImage: "person.crop.circle",
                    description: Text("Your Discogs profile will appear here.")
                )
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Log Out", role: .destructive) {
                    Task {
                        await authSession.logout()
                    }
                }
            }
        }
    }
}
