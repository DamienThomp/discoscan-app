//
//  SearchContext.swift
//  DiscoScan
//

import Foundation

enum SearchContext: Hashable, Sendable {
    case text(query: String)
    case barcode(code: String)
    case imageSuggested(query: String)
}

extension SearchContext {

    var endpoint: SearchEndpoint {
        switch self {
        case .text(let query), .imageSuggested(let query):
            SearchEndpoint(text: query)
        case .barcode(let code):
            SearchEndpoint(barcode: code)
        }
    }

    var cacheKey: String {
        switch self {
        case .text(let query):
            "search-text-\(query)"
        case .barcode(let code):
            "search-barcode-\(code)"
        case .imageSuggested(let query):
            "search-image-\(query)"
        }
    }

    var displayTitle: String {
        switch self {
        case .text(let query):
            query
        case .barcode(let code):
            code
        case .imageSuggested(let query):
            query
        }
    }

    var navigationTitle: String {
        switch self {
        case .text:
            "Results"
        case .barcode:
            "Barcode Results"
        case .imageSuggested:
            "Photo Matches"
        }
    }

    var resultsHeader: String {
        switch self {
        case .text(let query):
            "Results for \"\(query)\""
        case .barcode(let code):
            "Barcode \(code)"
        case .imageSuggested(let query):
            "Matches for \"\(query)\""
        }
    }

    var isBarcode: Bool {
        if case .barcode = self { return true }
        return false
    }
}
