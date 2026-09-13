//
//  AppRouteNavigationStack.swift
//  DiscoScan
//

import SwiftUI

struct AppRouteNavigationStack<Root: View>: View {
    @Binding var path: NavigationPath
    @ViewBuilder let root: () -> Root

    var body: some View {
        NavigationStack(path: $path) {
            root()
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteDestination(route: route)
                }
        }
    }
}
