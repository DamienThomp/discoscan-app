//
//  IdentificationImagePreview.swift
//  DiscoScan
//

import SwiftUI
import UIKit

struct IdentificationImagePreview: View {
    let imageData: Data
    var accessibilityLabel: String? = nil

    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.standard))
                .accessibilityHidden(accessibilityLabel == nil)
                .accessibilityLabel(accessibilityLabel ?? "")
        }
    }
}
