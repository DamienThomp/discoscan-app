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
    func identify(jpegData: Data) async throws -> SleeveIdentification
}