//
//  PreviewAppRouteStack.swift
//  DiscoScan
//

#if DEBUG
import SwiftUI

/// Wraps content in `AppRouteNavigationStack` for previews that use `NavigationLink(value: AppRoute…)`.
struct PreviewAppRouteStack<Root: View>: View {
    @State private var path = NavigationPath()
    @ViewBuilder let root: () -> Root

    var body: some View {
        AppRouteNavigationStack(path: $path, root: root)
    }
}
#endif
