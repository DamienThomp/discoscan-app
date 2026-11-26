//
//  SleeveIdentifierEnvironment.swift
//  DiscoScan
//

import SwiftUI

private struct UnimplementedSleeveIdentifier: SleeveIdentifierProtocol {
    var isOnDeviceAvailable: Bool { false }

    func identify(jpegData: Data, engine: SleeveIdentificationEngine) async throws -> SleeveIdentification {
        fatalError("sleeveIdentifier environment value was not injected.")
    }
}

private let unimplementedSleeveIdentifier = UnimplementedSleeveIdentifier()

extension EnvironmentValues {
    @Entry var sleeveIdentifier: any SleeveIdentifierProtocol = unimplementedSleeveIdentifier
}

#if DEBUG
struct PreviewSleeveIdentifier: SleeveIdentifierProtocol {
    var isOnDeviceAvailable = true

    func identify(jpegData: Data, engine: SleeveIdentificationEngine) async throws -> SleeveIdentification {
        SleeveIdentification(
            artist: "Miles Davis",
            title: "Kind of Blue",
            catalogNumber: nil
        )
    }
}
#endif
