//
//  ClearButtonModifier.swift
//  DiscoScan
//

import SwiftUI

private struct ClearButtonWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 22

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ClearButtonModifier: ViewModifier {
    @Binding var text: String
    let label: String

    @State private var buttonWidth: CGFloat = 22

    private let gap: CGFloat = 8
    private let hitAreaPadding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(.trailing, text.isEmpty ? 0 : buttonWidth + gap)
            .overlay(alignment: .trailing) {
                if !text.isEmpty {
                    clearButton
                }
            }
    }

    private var clearButton: some View {
        Button {
            text = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.body)
                .foregroundStyle(.tertiary)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ClearButtonWidthKey.self,
                            value: proxy.size.width
                        )
                    }
                }
                .padding(hitAreaPadding)
                .contentShape(Rectangle())
                .padding(-hitAreaPadding)
        }
        .buttonStyle(.plain)
        .onPreferenceChange(ClearButtonWidthKey.self) { buttonWidth = $0 }
        .accessibilityLabel("Clear \(label)")
    }
}

extension View {
    func clearable(text: Binding<String>, label: String) -> some View {
        modifier(ClearButtonModifier(text: text, label: label))
    }
}

