//
//  SleeveIdentifierProtocol.swift
//  DiscoScan
//

import Foundation

protocol SleeveIdentifierProtocol: Sendable {
    func identify(jpegData: Data) async throws -> SleeveIdentification
}
