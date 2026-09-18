//
//  SearchEndpointTests.swift
//  DiscoScanTests
//

import Foundation
import NetworkKit
import Testing
@testable import DiscoScan

struct SearchEndpointTests {

    @Test func textSearchQueryItems() {
        let endpoint = SearchEndpoint(text: "Kind of Blue")

        let items = endpoint.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "q", value: "Kind of Blue")))
        #expect(items.contains(URLQueryItem(name: "page", value: "1")))
        #expect(items.contains(URLQueryItem(name: "per_page", value: "25")))
        #expect(!items.contains(where: { $0.name == "barcode" }))
    }

    @Test func barcodeSearchQueryItems() {
        let endpoint = SearchEndpoint(barcode: "042283923518")

        let items = endpoint.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "barcode", value: "042283923518")))
        #expect(items.contains(URLQueryItem(name: "type", value: "release")))
        #expect(!items.contains(where: { $0.name == "q" }))
    }

    @Test func searchContextMapsToEndpointAndCacheKey() {
        let text = SearchContext.text(query: "Miles Davis")
        #expect(text.cacheKey == "search-text-Miles Davis")
        #expect(text.endpoint.queryItems?.contains(URLQueryItem(name: "q", value: "Miles Davis")) == true)

        let barcode = SearchContext.barcode(code: "123")
        #expect(barcode.cacheKey == "search-barcode-123")
        #expect(barcode.endpoint.queryItems?.contains(URLQueryItem(name: "barcode", value: "123")) == true)
    }
}
