//
//  OnDeviceSleeveGeneratorProtocol.swift
//  DiscoScan
//

import Foundation

nonisolated protocol OnDeviceSleeveGeneratorProtocol: Sendable {
    var isReady: Bool { get }
    func generate(jpegData: Data) async throws -> SleeveIdentification
}