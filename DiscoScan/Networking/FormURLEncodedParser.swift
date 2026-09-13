//
//  FormURLEncodedParser.swift
//  DiscoScan
//

import Foundation

nonisolated enum FormURLEncodedParser {
    static func parse(_ data: Data) throws -> [String: String] {
        guard let body = String(data: data, encoding: .utf8), !body.isEmpty else {
            return [:]
        }

        var result: [String: String] = [:]

        for pair in body.split(separator: "&") {
            let components = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard let key = components.first else { continue }
            let value = components.count > 1 ? components[1] : ""
            result[key] = value.removingPercentEncoding ?? value
        }

        return result
    }

    static func oauthTokens(from data: Data) throws -> OAuthTokens {
        let fields = try parse(data)

        guard
            let token = fields["oauth_token"],
            let tokenSecret = fields["oauth_token_secret"]
        else {
            throw FormURLEncodedParserError.missingOAuthFields
        }

        return OAuthTokens(token: token, tokenSecret: tokenSecret)
    }

    static func requestTokens(from data: Data) throws -> OAuthRequestTokens {
        let fields = try parse(data)

        guard
            let token = fields["oauth_token"],
            let tokenSecret = fields["oauth_token_secret"],
            fields["oauth_callback_confirmed"] == "true"
        else {
            throw FormURLEncodedParserError.missingOAuthFields
        }

        return OAuthRequestTokens(token: token, tokenSecret: tokenSecret)
    }
}

enum FormURLEncodedParserError: Error, LocalizedError {
    case missingOAuthFields

    var errorDescription: String? {
        switch self {
        case .missingOAuthFields:
            return "The OAuth response did not contain the expected token fields."
        }
    }
}
