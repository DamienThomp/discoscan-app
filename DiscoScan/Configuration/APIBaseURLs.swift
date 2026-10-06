//
//  APIBaseURLs.swift
//  DiscoScan
//

import Foundation

nonisolated struct APIBaseURLs: Sendable {
    let discogsAPI: URL
    let discogsWeb: URL
    let gemini: URL

    static func fromBundle() -> APIBaseURLs {
        APIBaseURLs(
            discogsAPI: url(forKey: "DISCOGSAPIBaseURL"),
            discogsWeb: url(forKey: "DISCOGSWebBaseURL"),
            gemini: url(forKey: "GEMINIAPIBaseURL")
        )
    }

    private static func url(forKey key: String) -> URL {
        guard
            let string = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            let url = URL(string: string),
            url.scheme == "https",
            url.host() != nil
        else {
            fatalError("Missing or invalid \(key). Check Configuration/App.xcconfig.")
        }
        return url
    }
}
