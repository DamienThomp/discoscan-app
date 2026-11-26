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
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Log Out", role: .destructive) {
                    Task {
                        await authSession.logout()
                    }
                }

                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
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
    AppRouteNavigationStack(path: .constant(NavigationPath())) {
        MyProfileView()
    }
    .environment(\.profileStore, previewProfileStore(.loaded))
    .environment(previewAuthenticatedAuthSession())
    .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
    .environment(\.geminiCredentialsStore, InMemoryGeminiCredentialsStore())
}

#Preview("Failed") {
    NavigationStack {
        MyProfileView()
    }
    .environment(\.profileStore, previewProfileStore(.failed("Could not load profile.")))
    .environment(previewAuthenticatedAuthSession())
    .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
    .environment(\.geminiCredentialsStore, InMemoryGeminiCredentialsStore())
}

#Preview("Loading") {
    NavigationStack {
        MyProfileView()
    }
    .environment(\.profileStore, previewProfileStore(.loading))
    .environment(previewAuthenticatedAuthSession())
    .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
    .environment(\.geminiCredentialsStore, InMemoryGeminiCredentialsStore())
}
#endif
