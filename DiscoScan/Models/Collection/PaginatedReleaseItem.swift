//
//  PaginatedReleaseItem.swift
//  DiscoScan
//

import Foundation

protocol PaginatedReleaseItem: Identifiable {
    var releaseId: Int { get }
    var basicInformation: ReleaseBasicInformation { get }
}

extension CollectionReleaseItem: PaginatedReleaseItem {}

extension WantListItem: PaginatedReleaseItem {
    var releaseId: Int { id }
}
