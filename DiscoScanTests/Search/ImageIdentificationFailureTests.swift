//
//  ImageIdentificationFailureTests.swift
//  DiscoScanTests
//

import Foundation
import Testing
@testable import DiscoScan

struct ImageIdentificationFailureTests {
    @Test func `Photo unavailable is not retryable`() {
        let failure = ImageIdentificationFailure.photoUnavailable

        #expect(failure.title == "Couldn't open that photo")
        #expect(failure.message == "Try a different image format or pick another photo.")
        #expect(failure.isRetryable == false)
        #expect(failure.isNotConfigured == false)
    }

    @Test func `Not configured is not retryable`() {
        let failure = ImageIdentificationFailure.identification(.notConfigured)

        #expect(failure.title == "Couldn't analyze this photo")
        #expect(failure.message == "Photo identification isn't available right now.")
        #expect(failure.isRetryable == false)
        #expect(failure.isNotConfigured == true)
    }

    @Test func `Offline failure is retryable`() {
        let failure = ImageIdentificationFailure.identification(.offline)

        #expect(failure.title == "Couldn't analyze this photo")
        #expect(failure.message == "You appear to be offline.")
        #expect(failure.isRetryable == true)
        #expect(failure.isNotConfigured == false)
    }

    @Test func `Rate limited failure is retryable`() {
        let failure = ImageIdentificationFailure.identification(.rateLimited)

        #expect(failure.isRetryable == true)
        #expect(failure.message == "Too many requests. Wait a moment, then try again.")
    }

    @Test func `Service unavailable failure is retryable`() {
        let failure = ImageIdentificationFailure.identification(.serviceUnavailable)

        #expect(failure.isRetryable == true)
        #expect(failure.message == "The identification service is unavailable.")
    }

    @Test func `Unreadable response failure is retryable`() {
        let failure = ImageIdentificationFailure.identification(.unreadableResponse)

        #expect(failure.isRetryable == true)
        #expect(failure.message == "Couldn't read the result.")
    }

    @Test func `Unknown failure is retryable`() {
        let failure = ImageIdentificationFailure.unknown

        #expect(failure.isRetryable == true)
        #expect(failure.message == "Something went wrong. Try again or choose another photo.")
    }

    @Test func `Init maps sleeve identification errors`() {
        let failure = ImageIdentificationFailure(error: SleeveIdentificationError.rateLimited)

        #expect(failure == .identification(.rateLimited))
    }

    @Test func `Init maps unknown errors`() {
        struct SampleError: Error {}

        let failure = ImageIdentificationFailure(error: SampleError())

        #expect(failure == .unknown)
    }
}
