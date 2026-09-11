//
//  AppRouter.swift
//  DiscoScan
//

import Observation
import SwiftUI

enum AppRoute: Hashable {
    case searchResults(query: String)
    case releaseDetail(id: Int)
    case profile(username: String)
}

@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
