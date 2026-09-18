//
//  SearchResultsEmptyView.swift
//  DiscoScan
//


import SwiftUI

struct SearchResultsEmptyView: View {
    let context: SearchContext

    var body: some View {
        ContentUnavailableView {
            Label(context.resultsHeader, systemImage: "magnifyingglass")
        } description: {
            Text("No releases matched this search.")
        }
    }
}
