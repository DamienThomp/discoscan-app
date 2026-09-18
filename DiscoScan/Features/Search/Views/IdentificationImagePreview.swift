//
//  IdentificationImagePreview.swift
//  DiscoScan
//

import SwiftUI
import UIKit

struct IdentificationImagePreview: View {
    let imageData: Data
    var maxHeight: CGFloat = 240

    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: maxHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
        }
    }
}
