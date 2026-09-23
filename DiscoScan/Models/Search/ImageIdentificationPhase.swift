//
//  ImageIdentificationPhase.swift
//  DiscoScan
//

import Foundation

enum ImageIdentificationPhase: Equatable {
    case capturing
    case analyzing
    case captureFailed(String)
    case confirming(SleeveIdentificationDraft)
}

enum ImageIdentificationFeedbackPhase: Equatable {
    case capturing
    case analyzing
    case failed
    case confirmed
}

extension ImageIdentificationPhase {
    var isCapturePhase: Bool {
        switch self {
        case .capturing, .analyzing, .captureFailed:
            true
        case .confirming:
            false
        }
    }

    var captureErrorMessage: String? {
        if case .captureFailed(let message) = self {
            message
        } else {
            nil
        }
    }

    var feedbackPhase: ImageIdentificationFeedbackPhase {
        switch self {
        case .capturing:
            .capturing
        case .analyzing:
            .analyzing
        case .captureFailed:
            .failed
        case .confirming:
            .confirmed
        }
    }
}
