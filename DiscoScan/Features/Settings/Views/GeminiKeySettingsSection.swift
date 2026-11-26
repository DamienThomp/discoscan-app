//
//  GeminiKeySettingsSection.swift
//  DiscoScan
//

import SwiftUI

struct GeminiKeySettingsSection: View {
    @Binding var apiKey: String
    @Binding var modelName: String
    let modelPlaceholder: String
    let onSave: () -> Void
    let onClear: () -> Void

    var body: some View {
        Section {
            SecureField("API Key", text: $apiKey)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Model", text: $modelName, prompt: Text(modelPlaceholder))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Save", action: onSave)
            Button("Clear", role: .destructive, action: onClear)
        } header: {
            Text("Gemini key")
        } footer: {
            Text("A saved key replaces the built-in key until you clear it. Leave the key blank to keep the saved key and update only the model.")
        }
    }
}
