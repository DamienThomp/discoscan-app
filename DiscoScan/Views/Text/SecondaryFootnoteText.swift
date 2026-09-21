//
//  SecondaryFootnoteText.swift
//  DiscoScan
//

import SwiftUI

struct SecondaryFootnoteText: View {
    let text: String
    var multilineTextAlignment: TextAlignment = .center

    var body: some View {
        Text(text)
            .appFootnoteHint(multilineTextAlignment: multilineTextAlignment)
    }
}

#if DEBUG
#Preview {
    SecondaryFootnoteText(text: "Photo ID works best with readable text or recognizable artwork.")
        .padding()
}
#endif
