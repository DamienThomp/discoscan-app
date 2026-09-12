//
//  MainTabView.swift
//  DiscoScan
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Collection", systemImage: "square.stack", value: .collection) {
                AppRouteNavigationStack(path: $router.collectionPath) {
                    CollectionView()
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                AppRouteNavigationStack(path: $router.searchPath) {
                    SearchView()
                }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                AppRouteNavigationStack(path: $router.profilePath) {
                    MyProfileView()
                }
            }
        }
    }
}
