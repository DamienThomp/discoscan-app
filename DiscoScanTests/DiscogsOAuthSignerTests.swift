//
//  DiscogsOAuthSignerTests.swift
//  DiscoScanTests
//

import Testing
@testable import DiscoScan

struct DiscogsOAuthSignerTests {
    @Test func requestTokenHeaderUsesConsumerSecretSignature() {
        let header = DiscogsOAuthSigner.authorizationHeader(
            consumerKey: "consumer-key",
            consumerSecret: "consumer-secret",
            callback: "discoscan://oauth/callback"
        )

        #expect(header.hasPrefix("OAuth "))
        #expect(header.contains("oauth_consumer_key=\"consumer-key\""))
        #expect(header.contains("oauth_signature=\"consumer-secret&\""))
        #expect(header.contains("oauth_signature_method=\"PLAINTEXT\""))
        #expect(header.contains("oauth_callback=\"discoscan://oauth/callback\""))
    }

    @Test func accessTokenHeaderUsesRequestTokenSecret() {
        let header = DiscogsOAuthSigner.authorizationHeader(
            consumerKey: "consumer-key",
            consumerSecret: "consumer-secret",
            token: "request-token",
            tokenSecret: "request-secret",
            verifier: "verifier-123"
        )

        #expect(header.contains("oauth_token=\"request-token\""))
        #expect(header.contains("oauth_verifier=\"verifier-123\""))
        #expect(header.contains("oauth_signature=\"consumer-secret&request-secret\""))
    }

    @Test func apiRequestHeaderUsesAccessTokenSecret() {
        let header = DiscogsOAuthSigner.authorizationHeader(
            consumerKey: "consumer-key",
            consumerSecret: "consumer-secret",
            token: "access-token",
            tokenSecret: "access-secret"
        )

        #expect(header.contains("oauth_token=\"access-token\""))
        #expect(header.contains("oauth_signature=\"consumer-secret&access-secret\""))
        #expect(!header.contains("oauth_verifier"))
        #expect(!header.contains("oauth_callback"))
    }
}
