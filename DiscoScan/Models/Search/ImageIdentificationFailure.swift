//
//  ImageIdentificationFailure.swift
//  DiscoScan
//

import Foundation

enum ImageIdentificationFailure: Equatable {
    case photoUnavailable
    case identification(SleeveIdentificationError)
    case unknown

    init(error: any Error) {
        if let error = error as? SleeveIdentificationError {
            self = .identification(error)
        } else {
            self = .unknown
        }
    }

    var title: String {
        switch self {
        case .photoUnavailable:
            "Couldn't open that photo"
        case .identification, .unknown:
            "Couldn't analyze this photo"
        }
    }

    var message: String {
        switch self {
        case .photoUnavailable:
            "Try a different image format or pick another photo."
        case .identification(.rateLimited):
            "Too many requests. Wait a moment, then try again."
        case .identification(.offline):
            "You appear to be offline."
        case .identification(.serviceUnavailable):
            "The identification service is unavailable."
        case .identification(.unreadableResponse):
            "Couldn't read the result."
        case .identification(.notConfigured):
            "Photo identification isn't available right now."
        case .unknown:
            "Something went wrong. Try again or choose another photo."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .photoUnavailable, .identification(.notConfigured):
            false
        case .identification(.offline), .identification(.rateLimited),
             .identification(.serviceUnavailable), .identification(.unreadableResponse), .unknown:
            true
        }
    }

    var isNotConfigured: Bool {
        if case .identification(.notConfigured) = self {
            true
        } else {
            false
        }
    }
}
