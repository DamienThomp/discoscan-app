//
//  DiscogsOAuthSigner.swift
//  DiscoScan
//

import Foundation

nonisolated enum DiscogsOAuthSigner {
    static func authorizationHeader(
        consumerKey: String,
        consumerSecret: String,
        token: String? = nil,
        tokenSecret: String? = nil,
        callback: String? = nil,
        verifier: String? = nil
    ) -> String {
        let signature = "\(consumerSecret)&\(tokenSecret ?? "")"
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString

        var parameters: [(String, String)] = [
            ("oauth_consumer_key", consumerKey),
            ("oauth_nonce", nonce),
            ("oauth_signature", signature),
            ("oauth_signature_method", "PLAINTEXT"),
            ("oauth_timestamp", timestamp)
        ]

        if let callback {
            parameters.append(("oauth_callback", callback))
        }

        if let token {
            parameters.append(("oauth_token", token))
        }

        if let verifier {
            parameters.append(("oauth_verifier", verifier))
        }

        let headerValues = parameters
            .map { key, value in
                "\(key)=\"\(percentEncode(value))\""
            }
            .joined(separator: ", ")

        return "OAuth \(headerValues)"
    }

    private static func percentEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
