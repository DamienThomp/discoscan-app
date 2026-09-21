//
//  OptionalInt+Display.swift
//  DiscoScan
//

import Foundation

extension Optional where Wrapped == Int {
    nonisolated var displayYear: Int? {
        guard let self, self > 0 else { return nil }
        return self
    }
}
