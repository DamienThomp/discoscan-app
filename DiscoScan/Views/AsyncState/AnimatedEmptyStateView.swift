//
//  AnimatedEmptyStateView.swift
//  DiscoScan
//

import SwiftUI

struct AnimatedEmptyStateView: View {
    struct Configuration {
        let title: String
        let systemImage: String
        let description: String
        var effect: Effect = .bounceDown

        enum Effect {
            case bounceDown
            case breathe
            case none
        }
    }

    let configuration: Configuration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = true

    var body: some View {
        ContentUnavailableView(
            configuration.title,
            systemImage: configuration.systemImage,
            description: Text(configuration.description)
        )
        .symbolRenderingMode(.multicolor)
        .modifier(
            EmptyStateSymbolEffectModifier(
                effect: configuration.effect,
                isAnimating: isAnimating && !reduceMotion
            )
        )
    }
}

private struct EmptyStateSymbolEffectModifier: ViewModifier {
    let effect: AnimatedEmptyStateView.Configuration.Effect
    let isAnimating: Bool

    func body(content: Content) -> some View {
        switch effect {
        case .bounceDown:
            content.symbolEffect(.bounce.down, options: .repeat(2), isActive: isAnimating)
        case .breathe:
            content.symbolEffect(.breathe, options: .speed(10).repeat(2), isActive: isAnimating)
        case .none:
            content
        }
    }
}

#if DEBUG
#Preview("Bounce") {
    AnimatedEmptyStateView(
        configuration: .init(
            title: "Collection",
            systemImage: "square.stack",
            description: "This folder is empty.",
            effect: .bounceDown
        )
    )
}

#Preview("Breathe") {
    AnimatedEmptyStateView(
        configuration: .init(
            title: "Want List",
            systemImage: "heart",
            description: "Your want list is empty.",
            effect: .breathe
        )
    )
}
#endif
