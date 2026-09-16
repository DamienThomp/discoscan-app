//
//  FolderName.swift
//  DiscoScan
//

import Foundation

enum FolderNameValidationError: LocalizedError, Equatable {
    case empty

    var errorDescription: String? {
        switch self {
        case .empty:
            "Folder name is required."
        }
    }
}

nonisolated struct FolderName: Equatable, Sendable {
    let value: String

    static func validated(from raw: String) -> Result<FolderName, FolderNameValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }
        return .success(FolderName(value: trimmed))
    }

    private init(value: String) {
        self.value = value
    }
}
