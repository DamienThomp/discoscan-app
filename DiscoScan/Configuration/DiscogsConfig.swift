//
//  DiscogsConfig.swift
//  DiscoScan
//

import Foundation

nonisolated struct DiscogsConfig: Sendable {
    let consumerKey: String
    let consumerSecret: String
    let callbackURL: URL
    let userAgent: String
    let callbackURLScheme: String

    static func fromBundle() -> DiscogsConfig {
        guard
            let consumerKey = Bundle.main.object(forInfoDictionaryKey: "DISCOGSConsumerKey") as? String,
            !consumerKey.isEmpty,
            let consumerSecret = Bundle.main.object(forInfoDictionaryKey: "DISCOGSConsumerSecret") as? String,
            !consumerSecret.isEmpty,
            let callbackURLString = Bundle.main.object(forInfoDictionaryKey: "DISCOGSCallbackURL") as? String,
            let callbackURL = URL(string: callbackURLString),
            let userAgent = Bundle.main.object(forInfoDictionaryKey: "DISCOGSUserAgent") as? String,
            !userAgent.isEmpty
        else {
            fatalError(
                """
                Missing Discogs configuration. Copy Configuration/Secrets.xcconfig.example to \
                Configuration/Secrets.xcconfig and set your consumer key and secret.
                """
            )
        }

        return DiscogsConfig(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            callbackURL: callbackURL,
            userAgent: userAgent,
            callbackURLScheme: callbackURL.scheme ?? "discoscan"
        )
    }
}
