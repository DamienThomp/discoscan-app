//
//  DetailSectionView.swift
//  DiscoScan
//

import SwiftUI

struct DetailSectionView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.metadata) {
            Text(title)
                .appSectionHeader()
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

#if DEBUG
#Preview {
    DetailSectionView(title: "Format", value: "Vinyl, LP, Album")
        .padding()
}
#endif
