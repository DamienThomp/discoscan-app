//
//  LoginView.swift
//  DiscoScan
//

import SwiftUI

struct LoginView: View {

    @Environment(AuthSession.self) private var authSession
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "opticaldisc.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("DiscoScan")
                .font(.largeTitle.bold())

            Text("Connect your Discogs account to search releases and manage your collection.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Connect with Discogs") {
                Task {
                    await authSession.login()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: authSession.state) { _, newValue in
            if case .failed = newValue {
                showErrorAlert = true
            }
        }
        .alert("Sign In Failed", isPresented: $showErrorAlert) {
            Button("OK") {
                authSession.dismissError()
            }
        } message: {
            if case .failed(let message) = authSession.state {
                Text(message)
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(previewAuthSession())
}
