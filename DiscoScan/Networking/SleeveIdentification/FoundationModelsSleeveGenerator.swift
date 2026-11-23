//
//  FoundationModelsSleeveGenerator.swift
//  DiscoScan
//

import CoreImage
import Foundation
import FoundationModels

struct FoundationModelsSleeveGenerator: OnDeviceSleeveGeneratorProtocol {
    private static let instructions = """
    You identify vinyl record sleeves. Extract the artist name, album title, and catalog number \
    only when they are printed on the sleeve. Leave a field empty if it is not visible; \
    never write placeholder words like "null" or "unknown".
    """

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
        let session = LanguageModelSession(instructions: Self.instructions)
        let response = try await session.respond(generating: OnDeviceSleeveIdentification.self) {
            "Identify this record sleeve."
            Attachment(image)
        }
        return response.content.identification
    }
}

@Generable
private nonisolated struct OnDeviceSleeveIdentification {
    @Guide(description: "Artist name as printed on the sleeve, or omit if not visible")
    var artist: String?
    @Guide(description: "Album title as printed on the sleeve, or omit if not visible")
    var title: String?
    @Guide(description: "Catalog number exactly as printed, or omit if not visible")
    var catalogNumber: String?

    var identification: SleeveIdentification {
        SleeveIdentification(artist: artist, title: title, catalogNumber: catalogNumber)
    }
}