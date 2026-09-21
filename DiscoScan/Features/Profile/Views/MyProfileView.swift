//
//  MyProfileView.swift
//  DiscoScan
//

import SwiftUI

struct MyProfileView: View {
    @Environment(\.profileStore) private var store
    @Environment(AuthSession.self) private var authSession

    var body: some View {
        ResourceContainerView(
            state: store.profile,
            retry: { await store.loadProfile(forceRefresh: true) }
        ) { profile in
            MyProfileContent(profile: profile)
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
        .task {
            if store.profile == .idle {
                await store.loadProfile()
            }
        }
        .refreshable {
            await store.loadProfile(forceRefresh: true)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack {
        MyProfileView()
    }
    .environment(\.profileStore, previewProfileStore(.loaded))
    .environment(previewAuthenticatedAuthSession())
}

#Preview("Failed") {
    NavigationStack {
        MyProfileView()
    }
    .environment(\.profileStore, previewProfileStore(.failed("Could not load profile.")))
    .environment(previewAuthenticatedAuthSession())
}

#Preview("Loading") {
    NavigationStack {
        MyProfileView()
    }
    .environment(\.profileStore, previewProfileStore(.loading))
    .environment(previewAuthenticatedAuthSession())
}
#endif
