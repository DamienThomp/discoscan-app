//
//  AppRouter.swift
//  DiscoScan
//

import Observation
import SwiftUI

enum AppTab: Hashable {
    case collection
    case search
    case profile
}

enum AppRoute: Hashable {
    case searchResults(query: String)
    case releaseDetail(id: Int)
    case userProfile(username: String)
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .collection
    var collectionPath = NavigationPath()
    var searchPath = NavigationPath()
    var profilePath = NavigationPath()

    func navigate(to route: AppRoute, tab: AppTab? = nil) {
        let target = tab ?? selectedTab
        selectedTab = target
        switch target {
        case .collection:
            collectionPath.append(route)
        case .search:
            searchPath.append(route)
        case .profile:
            profilePath.append(route)
        }
    }

    func reset() {
        selectedTab = .collection
        collectionPath = NavigationPath()
        searchPath = NavigationPath()
        profilePath = NavigationPath()
    }
}
