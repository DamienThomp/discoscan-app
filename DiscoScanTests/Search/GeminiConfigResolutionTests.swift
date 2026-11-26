//
//  GeminiConfigResolutionTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct GeminiConfigResolutionTests {
    private let bundle = GeminiConfig(apiKey: "bundle-key", modelName: "bundle-model")

    @Test func `Blank saved model uses the default model name`() {
        let saved = GeminiCredentials(apiKey: "user-key", modelName: "  ")
        let config = GeminiConfig.resolve(saved: saved, bundle: nil)

        #expect(config == GeminiConfig(
            apiKey: "user-key",
            modelName: SleeveIdentificationEngine.defaultModelName
        ))
    }

    @Test func `Blank saved model uses the bundle model`() {
        let saved = GeminiCredentials(apiKey: "user-key", modelName: "")
        let config = GeminiConfig.resolve(saved: saved, bundle: bundle)

        #expect(config?.apiKey == "user-key")
        #expect(config?.modelName == "bundle-model")
    }

    @Test func `Saved key replaces the bundle key`() {
        let saved = GeminiCredentials(apiKey: "user-key", modelName: "user-model")
        let config = GeminiConfig.resolve(saved: saved, bundle: bundle)

        #expect(config == GeminiConfig(apiKey: "user-key", modelName: "user-model"))
    }

    @Test func `Empty saved key falls through to the bundle`() {
        let saved = GeminiCredentials(apiKey: "   ", modelName: "user-model")
        let config = GeminiConfig.resolve(saved: saved, bundle: bundle)

        #expect(config == bundle)
    }

    @Test func `Missing credentials fall through to the bundle`() {
        let config = GeminiConfig.resolve(saved: nil, bundle: bundle)

        #expect(config == bundle)
    }

    @Test func `Store resolved config prefers the saved key`() async {
        let store = InMemoryGeminiCredentialsStore(
            saved: GeminiCredentials(apiKey: "user-key", modelName: ""),
            bundleConfig: bundle
        )

        let config = await store.resolvedConfig()

        #expect(config?.apiKey == "user-key")
        #expect(config?.modelName == "bundle-model")
    }
}

struct SleeveIdentificationEngineTests {
    @Test func `On-device stays on-device when the model is available`() {
        let engine = SleeveIdentificationEngine.onDevice.effectiveEngine(
            isOnDeviceAvailable: true,
            hasCloudConfig: true
        )

        #expect(engine == .onDevice)
    }

    @Test func `On-device uses cloud when the model is unavailable and a key exists`() {
        let engine = SleeveIdentificationEngine.onDevice.effectiveEngine(
            isOnDeviceAvailable: false,
            hasCloudConfig: true
        )

        #expect(engine == .cloud)
    }

    @Test func `On-device stays on-device when no key exists`() {
        let engine = SleeveIdentificationEngine.onDevice.effectiveEngine(
            isOnDeviceAvailable: false,
            hasCloudConfig: false
        )

        #expect(engine == .onDevice)
    }

    @Test func `Cloud without a key is treated as on-device`() {
        let engine = SleeveIdentificationEngine.cloud.effectiveEngine(
            isOnDeviceAvailable: true,
            hasCloudConfig: false
        )

        #expect(engine == .onDevice)
    }

    @Test func `Cloud with a key stays on cloud`() {
        let engine = SleeveIdentificationEngine.cloud.effectiveEngine(
            isOnDeviceAvailable: true,
            hasCloudConfig: true
        )

        #expect(engine == .cloud)
    }
}
