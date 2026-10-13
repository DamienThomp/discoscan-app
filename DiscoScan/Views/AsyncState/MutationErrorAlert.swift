//
//  MutationErrorAlert.swift
//  DiscoScan
//

import SwiftUI

struct MutationErrorAlert: ViewModifier {
    @Binding var message: String?
    let title: LocalizedStringKey

    func body(content: Content) -> some View {
        content.alert(
            title,
            isPresented: $message.isNonNil,
            presenting: message
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
    }
}

extension View {
    func mutationErrorAlert(title: LocalizedStringKey, message: Binding<String?>) -> some View {
        modifier(MutationErrorAlert(message: message, title: title))
    }
}
