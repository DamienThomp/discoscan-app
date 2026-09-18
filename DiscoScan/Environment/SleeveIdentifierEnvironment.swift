//
//  SleeveIdentifierEnvironment.swift
//  DiscoScan
//

import SwiftUI

private struct UnimplementedSleeveIdentifier: SleeveIdentifierProtocol {
    func identify(jpegData: Data) async throws -> SleeveIdentification {
        fatalError("sleeveIdentifier environment value was not injected.")
    }
}

private let unimplementedSleeveIdentifier = UnimplementedSleeveIdentifier()

extension EnvironmentValues {
    @Entry var sleeveIdentifier: any SleeveIdentifierProtocol = unimplementedSleeveIdentifier
}

#if DEBUG
struct PreviewSleeveIdentifier: SleeveIdentifierProtocol {
    func identify(jpegData: Data) async throws -> SleeveIdentification {
        SleeveIdentification(
            artist: "Miles Davis",
            title: "Kind of Blue",
            catalogNumber: nil
        )
    }
}
#endif
