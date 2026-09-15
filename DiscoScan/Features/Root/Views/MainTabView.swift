//
//  MainTabView.swift
//  DiscoScan
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    @State private var searchText: String = ""

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
                    SearchView()
                }.searchable(text: $searchText)
            }
        }
    }
}

