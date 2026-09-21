//
//  DiscogsUserProfileTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct DiscogsUserProfileTests {

    @Test func decodesFullProfile() throws {
        let profile = try decodeProfile(
            """
            {
                "username": "tester",
                "name": "Test User",
                "profile": "Hello from Discogs.",
                "location": "Portland, OR",
                "registered": "2005-08-05T12:59:27",
                "num_collection": 42,
                "avatar_url": "https://i.discogs.com/avatar.jpg"
            }
            """
        )

        #expect(profile.username == "tester")
        #expect(profile.name == "Test User")
        #expect(profile.profile == "Hello from Discogs.")
        #expect(profile.location == "Portland, OR")
        #expect(profile.registered == "2005-08-05T12:59:27")
        #expect(profile.numCollection == 42)
        #expect(profile.avatarUrl == "https://i.discogs.com/avatar.jpg")
        #expect(profile.avatarImageURL == URL(string: "https://i.discogs.com/avatar.jpg"))
    }

    @Test func emptyAvatarURLStringDecodesToNilImageURL() throws {
        let profile = try decodeProfile(
            """
            {
                "username": "tester",
                "avatar_url": ""
            }
            """
        )

        #expect(profile.avatarUrl == "")
        #expect(profile.avatarImageURL == nil)
    }

    @Test func omittedOptionalFieldsDecodeAsNil() throws {
        let profile = try decodeProfile(
            """
            {
                "username": "tester"
            }
            """
        )

        #expect(profile.username == "tester")
        #expect(profile.name == nil)
        #expect(profile.profile == nil)
        #expect(profile.location == nil)
        #expect(profile.registered == nil)
        #expect(profile.numCollection == nil)
        #expect(profile.avatarUrl == nil)
        #expect(profile.avatarImageURL == nil)
    }

    private func decodeProfile(_ json: String) throws -> DiscogsUserProfile {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(DiscogsUserProfile.self, from: Data(json.utf8))
    }
}
