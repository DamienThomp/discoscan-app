//
//  UserProfileView.swift
//  DiscoScan
//

import SwiftUI

struct UserProfileView: View {
    let username: String

    var body: some View {
        ContentUnavailableView(
            username,
            systemImage: "person.crop.circle",
            description: Text("Profile navigation is wired and ready for a dedicated endpoint.")
        )
        .navigationTitle("Profile")
    }
}
