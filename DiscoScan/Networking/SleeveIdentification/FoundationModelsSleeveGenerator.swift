//
//  FoundationModelsSleeveGenerator.swift
//  DiscoScan
//

import CoreImage
import Foundation
import FoundationModels

struct FoundationModelsSleeveGenerator: OnDeviceSleeveGeneratorProtocol {
    var isReady: Bool {
        guard #available(iOS 27.0, *) else { return false }
        let model = SystemLanguageModel.default
        return model.isAvailable && model.capabilities.contains(.vision)
    }

    func generate(jpegData: Data) async throws -> SleeveIdentification {
        guard #available(iOS 27.0, *) else {
            throw SleeveIdentificationError.notConfigured
        }
        guard let image = CIImage(data: jpegData, options: [.applyOrientationProperty: true]) else {
            throw SleeveIdentificationError.unreadableResponse
        }
        let session = LanguageModelSession(instructions: SleeveIdentifier.prompt)
        let response = try await session.respond(generating: OnDeviceSleeveIdentification.self) {
            "Identify this record sleeve."
            Attachment(image)
        }
        return response.content.identification
    }
}

@Generable
private nonisolated struct OnDeviceSleeveIdentification {
    @Guide(description: "Artist name as printed on the sleeve")
    var artist: String?
    @Guide(description: "Album title as printed on the sleeve")
    var title: String?
    @Guide(description: "Catalog number if visible")
    var catalogNumber: String?

    var identification: SleeveIdentification {
        SleeveIdentification(artist: artist, title: title, catalogNumber: catalogNumber)
    }
}