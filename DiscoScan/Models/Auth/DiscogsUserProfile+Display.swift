//
//  DiscogsUserProfile+Display.swift
//  DiscoScan
//

import Foundation

extension DiscogsUserProfile {
    var displayName: String {
        name ?? username
    }

    var displayRegisteredDate: String {
        guard let registered else { return "Unknown" }
        guard let date = Self.parseRegisteredDate(registered) else {
            return registered
        }
        return Self.memberSinceFormatter.string(from: date)
    }

    var displayCollectionCount: String {
        guard let numCollection else { return "—" }
        return String(numCollection)
    }

    private static func parseRegisteredDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        for options: ISO8601DateFormatter.Options in [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime],
            [.withFullDate, .withFullTime]
        ] {
            iso.formatOptions = options
            if let date = iso.date(from: string) {
                return date
            }
        }
        return nil
    }

    private static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
