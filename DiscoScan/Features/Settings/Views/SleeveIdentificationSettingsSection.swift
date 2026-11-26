//
//  SleeveIdentificationSettingsSection.swift
//  DiscoScan
//

import SwiftUI

struct SleeveIdentificationSettingsSection: View {
    @Binding var preferredEngine: SleeveIdentificationEngine
    let isOnDeviceAvailable: Bool
    let hasCloudConfig: Bool

    var body: some View {
        Section {
            Picker("Identify with", selection: $preferredEngine) {
                Text("On Device")
                    .tag(SleeveIdentificationEngine.onDevice)
                    .disabled(!isOnDeviceAvailable)
                if hasCloudConfig {
                    Text("Cloud")
                        .tag(SleeveIdentificationEngine.cloud)
                }
            }
            .pickerStyle(.inline)
            .disabled(!isOnDeviceAvailable && !hasCloudConfig)
        } header: {
            Text("Sleeve identification")
        } footer: {
            Text(footer)
        }
    }

    private var footer: String {
        if !isOnDeviceAvailable && !hasCloudConfig {
            return "Add a Gemini API key to identify sleeves. On-device identification isn't available on this iPhone."
        }
        if !isOnDeviceAvailable {
            return "On-device identification isn't available on this iPhone. Cloud sends the photo to Google Gemini."
        }
        return "On Device keeps photos on your iPhone. Cloud sends them to Google Gemini using your saved key, or the built-in key when you haven't saved one."
    }
}
