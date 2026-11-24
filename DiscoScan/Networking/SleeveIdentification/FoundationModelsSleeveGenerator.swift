//
//  FoundationModelsSleeveGenerator.swift
//  DiscoScan
//

import CoreImage
import Foundation
import FoundationModels

struct FoundationModelsSleeveGenerator: OnDeviceSleeveGeneratorProtocol {
    private static let instructions = """
    You read a vinyl record sleeve to determine its artist, album title, and catalog number. \
    Handle every field in this strict priority order:

    1. Transcribe text printed on the sleeve. Copy it exactly as it appears — do not correct, \
    translate, or complete it. Printed text is always the source of truth.
    2. Only if a field has no legible printed text may you infer it from the cover imagery \
    (photo, logo, artwork). This is a last resort, never your first choice.

    Rules:
    - The photo may show more than the sleeve. Ignore everything that is not printed on the record \
    sleeve itself: price stickers, barcode labels, shrink wrap, store signs, shelves, and other \
    records nearby.
    - First list the most prominent printed text from the sleeve in visibleText, copied exactly, \
    before filling artist, title, or catalog number. List each piece of text once; never repeat an \
    entry.
    - If any printed text names the artist or title, you MUST use that text, even when a photograph \
    suggests a different person. Never override readable text with a guess from a face, pose, or \
    musical style.
    - Do not use outside knowledge to change text you can already read.
    - If you can neither read nor reasonably infer a field, leave it empty.
    - Never output placeholder words such as "null", "unknown", or "n/a".
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
        let model = SystemLanguageModel.default
        let reasoningLevel: ContextOptions.ReasoningLevel? =
            model.capabilities.contains(.reasoning) ? .light : nil
        let session = LanguageModelSession(instructions: Self.instructions)
        let response = try await session.respond(
            generating: OnDeviceSleeveIdentification.self,
            options: GenerationOptions(samplingMode: .greedy, maximumResponseTokens: 512),
            contextOptions: ContextOptions(
                includeSchemaInPrompt: true,
                reasoningLevel: reasoningLevel
            )
        ) {
            "Read this record sleeve and fill in the fields."
            Attachment(image)
        }
        return response.content.identification
    }
}

@Generable
private nonisolated struct OnDeviceSleeveIdentification {
    @Guide(
        description: """
        The most prominent text printed on the record sleeve itself, largest first, copied exactly. \
        Exclude price stickers, store signs, and other records. Each entry appears once. Do not invent \
        or complete partial words. Empty list if none is legible.
        """,
        .maximumCount(8)
    )
    var visibleText: [String]
    @Guide(
        description: """
        Artist or band name. Use the name printed on the sleeve whenever any is legible; infer from \
        cover imagery only if no name is printed. Empty if you cannot determine it.
        """
    )
    var artist: String?
    @Guide(
        description: """
        Album or release title. Prefer the title printed on the sleeve, copied verbatim; infer from \
        imagery only if none is printed. Empty if you cannot determine it.
        """
    )
    var title: String?
    @Guide(
        description: """
        Catalog number exactly as printed on the sleeve or spine. This is always printed text and must \
        never be inferred from imagery. Empty if not printed.
        """
    )
    var catalogNumber: String?

    var identification: SleeveIdentification {
        SleeveIdentification(artist: artist, title: title, catalogNumber: catalogNumber)
    }
}