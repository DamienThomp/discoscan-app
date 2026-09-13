//
//  DiscoScanApp.swift
//  DiscoScan
//

import NetworkKit
import SwiftUI

@main
struct DiscoScanApp: App {
    @State private var authSession: AuthSession
    @State private var router = AppRouter()
    private let apiClient: any NetworkManagerProtocol

    init() {
        let dependencies = AppDependencies.make()
        apiClient = dependencies.apiClient
        _authSession = State(initialValue: AuthSession(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authSession)
                .environment(router)
                .environment(\.discogsClient, apiClient)
                .task {
                    await authSession.bootstrap()
                }
        }
    }
}
