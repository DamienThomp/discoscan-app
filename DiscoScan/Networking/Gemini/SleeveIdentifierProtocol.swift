//
//  SleeveIdentifierProtocol.swift
//  DiscoScan
//

import Foundation

enum SleeveIdentificationError: Error, Equatable {
    case rateLimited
    case offline
    case serviceUnavailable
    case notConfigured
    case unreadableResponse
}

protocol SleeveIdentifierProtocol: Sendable {
    func identify(jpegData: Data) async throws -> SleeveIdentification
}
