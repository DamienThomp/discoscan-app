//
//  SleeveIdentificationEngine.swift
//  DiscoScan
//

import Foundation

nonisolated enum SleeveIdentificationEngine: String, CaseIterable, Sendable {
    case onDevice
    case cloud

    static let storageKey = "sleeveIdentificationEngine"
    static let defaultModelName = "gemini-3.5-flash-lite"

    func effectiveEngine(isOnDeviceAvailable: Bool, hasCloudConfig: Bool) -> SleeveIdentificationEngine {
        switch self {
        case .onDevice:
            if !isOnDeviceAvailable && hasCloudConfig {
                return .cloud
            }
            return .onDevice
        case .cloud:
            if hasCloudConfig {
                return .cloud
            }
            return .onDevice
        }
    }

    var captureCaption: String {
        switch self {
        case .onDevice:
            "Identifying on device"
        case .cloud:
            "Identifying with cloud (Gemini)"
        }
    }

    static func clearStoredPreference(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }
}
