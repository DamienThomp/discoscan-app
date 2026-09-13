//
//  DiscogsClientEnvironment.swift
//  DiscoScan
//

import NetworkKit
import SwiftUI

private final class UnimplementedNetworkClient: NetworkManagerProtocol, @unchecked Sendable {
    func request<E: EndpointProtocol>(for endpoint: E) async throws -> E.Response {
        fatalError("discogsClient environment value was not injected.")
    }

    func requestData<E: EndpointProtocol>(for endpoint: E) async throws -> Data {
        fatalError("discogsClient environment value was not injected.")
    }
}

extension EnvironmentValues {
    @Entry var discogsClient: NetworkManagerProtocol = UnimplementedNetworkClient()
}
