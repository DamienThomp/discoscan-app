//
//  MainTabView.swift
//  DiscoScan
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    @State private var searchText = ""

    private let recentSearchStore = RecentSearchStore()

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Collection", systemImage: "square.stack", value: .collection) {
                AppRouteNavigationStack(path: $router.collectionPath) {
                    CollectionView()
                }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                AppRouteNavigationStack(path: $router.profilePath) {
                    MyProfileView()
                }
            }

            Tab(value: .search, role: .search) {
                AppRouteNavigationStack(path: $router.searchPath) {
                    SearchView(searchText: $searchText)
                }
                .searchable(text: $searchText, prompt: "Artists, albums, labels…")
                .onSubmit(of: .search) {
                    submitTextSearch()
                }
                .searchSuggestions {
                    ForEach(recentSearchStore.load(), id: \.self) { query in
                        Text(query).searchCompletion(query)
                    }
                }
            }
        }
    }

    private func submitTextSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        recentSearchStore.add(query)
        router.submitSearch(.text(query: query))
    }
}
