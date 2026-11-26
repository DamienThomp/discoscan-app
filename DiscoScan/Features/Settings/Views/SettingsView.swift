//
//  SettingsView.swift
//  DiscoScan
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.sleeveIdentifier) private var sleeveIdentifier
    @Environment(\.geminiCredentialsStore) private var credentialsStore
    @Environment(\.geminiCredentialsVerifier) private var geminiCredentialsVerifier
    @AppStorage(SleeveIdentificationEngine.storageKey) private var preferredEngine: SleeveIdentificationEngine = .onDevice

    @State private var apiKey = ""
    @State private var modelName = ""
    @State private var hasCloudConfig = false
    @State private var modelPlaceholder = SleeveIdentificationEngine.defaultModelName
    @State private var isVerifying = false
    @State private var alertTitle: LocalizedStringKey = "Couldn't Save Key"
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
                isVerifying: isVerifying,
                onSave: saveCredentials,
                onClear: clearCredentials
            )
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCredentials()
        }
        .mutationErrorAlert(title: alertTitle, message: $saveError)
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

        guard let resolved = GeminiConfig.resolve(
            saved: GeminiCredentials(apiKey: key, modelName: typedModel),
            bundle: GeminiConfig.fromBundleIfPresent()
        ) else { return }

        isVerifying = true
        defer { isVerifying = false }

        let verification: GeminiCredentialsVerification
        do {
            verification = try await geminiCredentialsVerifier.verify(resolved)
        } catch is CancellationError {
            return
        } catch {
            alertTitle = "Couldn't Save Key"
            saveError = GeminiCredentialsVerification.unavailable.message
            return
        }

        guard verification.shouldSave else {
            alertTitle = "Couldn't Save Key"
            saveError = verification.message
            return
        }

        do {
            try await credentialsStore.save(GeminiCredentials(apiKey: key, modelName: typedModel))
            apiKey = key
            hasCloudConfig = await credentialsStore.resolvedConfig() != nil
            if let message = verification.message {
                alertTitle = "Gemini Quota"
                saveError = message
            }
        } catch {
            alertTitle = "Couldn't Save Key"
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
            alertTitle = "Couldn't Save Key"
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
    .environment(\.geminiCredentialsVerifier, PreviewGeminiCredentialsVerifier())
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
    .environment(\.geminiCredentialsVerifier, PreviewGeminiCredentialsVerifier())
    .environment(\.geminiCredentialsStore, InMemoryGeminiCredentialsStore())
}
#endif
