//
//  AppleMusicCatalogEnvironment.swift
//  DiscoScan
//

import SwiftUI

private struct UnimplementedAppleMusicCatalog: AppleMusicCatalogProtocol {
    func albumURL(for release: ReleaseDetailResponse) async -> URL? {
        fatalError("appleMusicCatalog environment value was not injected.")
    }
}

private let unimplementedAppleMusicCatalog = UnimplementedAppleMusicCatalog()

extension EnvironmentValues {
    @Entry var appleMusicCatalog: any AppleMusicCatalogProtocol = unimplementedAppleMusicCatalog
}

#if DEBUG
struct PreviewAppleMusicCatalog: AppleMusicCatalogProtocol {
    func albumURL(for release: ReleaseDetailResponse) async -> URL? {
        URL(string: "https://music.apple.com/us/album/example/1234567890")
    }
}
#endif
