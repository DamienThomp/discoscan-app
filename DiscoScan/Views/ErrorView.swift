//
//  ErrorView.swift
//  DiscoScan
//

import SwiftUI

struct ErrorView: View {

    var message: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            VStack {
                Image(systemName: "opticaldisc.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .padding()
            }
        } description: {
            if let message {
                Text(message)
            }
        } actions: {
            if let action {
                Button {
                    action()
                } label: {
                    Text("Retry")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ErrorView(message: "something went wrong", action: { print("retry") })
}
