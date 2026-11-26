//
//  SleeveIdentifierProtocol.swift
//  DiscoScan
//

import Foundation

nonisolated enum SleeveIdentificationError: Error, Equatable {
    case rateLimited
    case offline
    case serviceUnavailable
    case notConfigured
    case unreadableResponse
}

nonisolated protocol SleeveIdentifierProtocol: Sendable {
    var isOnDeviceAvailable: Bool { get }
    func identify(jpegData: Data, engine: SleeveIdentificationEngine) async throws -> SleeveIdentification
}
