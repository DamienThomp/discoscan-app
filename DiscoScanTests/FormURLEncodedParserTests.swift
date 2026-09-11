//
//  FormURLEncodedParserTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct FormURLEncodedParserTests {
    @Test func parsesOAuthAccessTokenResponse() throws {
        let data = Data("oauth_token=abc123&oauth_token_secret=xyz789".utf8)
        let tokens = try FormURLEncodedParser.oauthTokens(from: data)

        #expect(tokens.token == "abc123")
        #expect(tokens.tokenSecret == "xyz789")
    }

    @Test func parsesOAuthRequestTokenResponse() throws {
        let data = Data(
            "oauth_token=req123&oauth_token_secret=reqsec&oauth_callback_confirmed=true".utf8
        )
        let tokens = try FormURLEncodedParser.requestTokens(from: data)

        #expect(tokens.token == "req123")
        #expect(tokens.tokenSecret == "reqsec")
    }
}
