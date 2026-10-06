//
//  MutationErrorAlert.swift
//  DiscoScan
//

import SwiftUI

struct MutationErrorAlert: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?

    func body(content: Content) -> some View {
        content.alert(title, isPresented: $isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}

extension View {
    func mutationErrorAlert(
        title: String,
        isPresented: Binding<Bool>,
        message: String?
    ) -> some View {
        modifier(MutationErrorAlert(isPresented: isPresented, title: title, message: message))
    }
}
