//
//  DiscogsOAuthServiceTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

@MainActor
struct DiscogsOAuthServiceTests {
    private let config = DiscogsConfig(
        consumerKey: "consumer-key",
        consumerSecret: "consumer-secret",
        callbackURL: URL(string: "discoscan://oauth/callback")!,
        userAgent: "DiscoScanTests/1.0",
        callbackURLScheme: "discoscan"
    )

    @Test func fetchRequestTokenParsesResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/oauth/request_token")
            #expect(request.value(forHTTPHeaderField: "User-Agent") == self.config.userAgent)
            #expect(request.value(forHTTPHeaderField: "Authorization")?.contains("oauth_callback") == true)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(
                "oauth_token=req-token&oauth_token_secret=req-secret&oauth_callback_confirmed=true".utf8
            )
            return (response, data)
        }

        let service = makeService()
        let tokens = try await service.fetchRequestToken()

        #expect(tokens.token == "req-token")
        #expect(tokens.tokenSecret == "req-secret")
    }

    @Test func exchangeAccessTokenParsesResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/oauth/access_token")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization")?.contains("oauth_verifier") == true)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data("oauth_token=access-token&oauth_token_secret=access-secret".utf8)
            return (response, data)
        }

        let service = makeService()
        let tokens = try await service.exchangeAccessToken(
            requestToken: "req-token",
            requestTokenSecret: "req-secret",
            verifier: "verifier"
        )

        #expect(tokens.token == "access-token")
        #expect(tokens.tokenSecret == "access-secret")
    }

    private func makeService() -> DiscogsOAuthService {
        let client = NetworkManagerFactory.makeDefaultClient(
            hostResolver: { _ in URL(string: "https://api.discogs.com")! },
            customInterceptors: [UserAgentInterceptor(userAgent: config.userAgent)],
            session: MockURLSessionFactory.make()
        )

        return DiscogsOAuthService(
            config: config,
            handshakeClient: client,
            tokenStore: InMemoryTokenStore()
        )
    }
}
