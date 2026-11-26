//
//  SettingsView.swift
//  DiscoScan
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.sleeveIdentifier) private var sleeveIdentifier
    @Environment(\.geminiCredentialsStore) private var credentialsStore
    @AppStorage(SleeveIdentificationEngine.storageKey) private var preferredEngine: SleeveIdentificationEngine = .onDevice

    @State private var apiKey = ""
    @State private var modelName = ""
    @State private var hasCloudConfig = false
    @State private var modelPlaceholder = SleeveIdentificationEngine.defaultModelName
    @State private var saveError: String?

    var body: some View {
        Form {
            SleeveIdentificationSettingsSection(
                preferredEngine: $preferredEngine,
                isOnDeviceAvailable: sleeveIdentifier.isOnDeviceAvailable,
                hasCloudConfig: hasCloudConfig
            )
            GeminiKeySettingsSection(
                apiKey: $apiKey,
                modelName: $modelName,
                modelPlaceholder: modelPlaceholder,
                onSave: saveCredentials,
                onClear: clearCredentials
            )
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCredentials()
        }
        .mutationErrorAlert(title: "Couldn't Save Key", message: $saveError)
    }

    private func loadCredentials() async {
        modelPlaceholder = GeminiConfig.fromBundleIfPresent()?.modelName
            ?? SleeveIdentificationEngine.defaultModelName

        if let saved = await credentialsStore.load() {
            apiKey = saved.apiKey
            modelName = saved.modelName
        }

        hasCloudConfig = await credentialsStore.resolvedConfig() != nil
        preferredEngine = preferredEngine.effectiveEngine(
            isOnDeviceAvailable: sleeveIdentifier.isOnDeviceAvailable,
            hasCloudConfig: hasCloudConfig
        )
    }

    private func saveCredentials() {
        Task {
            await save()
        }
    }

    private func clearCredentials() {
        Task {
            await clear()
        }
    }

    private func save() async {
        let typedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let typedModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = await credentialsStore.load()
        let key = typedKey.isEmpty ? (existing?.apiKey ?? "") : typedKey
        guard !key.isEmpty else { return }

        do {
            try await credentialsStore.save(GeminiCredentials(apiKey: key, modelName: typedModel))
            apiKey = key
            hasCloudConfig = await credentialsStore.resolvedConfig() != nil
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func clear() async {
        do {
            try await credentialsStore.clear()
            apiKey = ""
            modelName = ""
            hasCloudConfig = await credentialsStore.resolvedConfig() != nil
            preferredEngine = preferredEngine.effectiveEngine(
                isOnDeviceAvailable: sleeveIdentifier.isOnDeviceAvailable,
                hasCloudConfig: hasCloudConfig
            )
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview("Key Saved") {
    NavigationStack {
        SettingsView()
    }
    .environment(\.sleeveIdentifier, PreviewSleeveIdentifier())
    .environment(
        \.geminiCredentialsStore,
        InMemoryGeminiCredentialsStore(
            saved: GeminiCredentials(apiKey: "preview-key", modelName: "gemini-3.5-flash-lite")
        )
    )
}

#Preview("No Key") {
    NavigationStack {
        SettingsView()
    }
    .environment(\.sleeveIdentifier, PreviewSleeveIdentifier(isOnDeviceAvailable: false))
    .environment(\.geminiCredentialsStore, InMemoryGeminiCredentialsStore())
}
#endif
