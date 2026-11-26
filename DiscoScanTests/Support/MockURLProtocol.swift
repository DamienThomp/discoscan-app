//
//  MockURLProtocol.swift
//  DiscoScan
//

import Foundation
import Synchronization

final class MockURLProtocol: URLProtocol {
    private typealias RequestHandler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let requestHandler = Mutex<RequestHandler?>(nil)
    private static let gate = HandlerGate()

    /// Runs a test body with an exclusive mock handler so parallel suites do not clobber each other.
    ///
    /// Waiting suites suspend rather than block a thread; a blocking lock held across `await`
    /// starves the main actor and cooperative pool and deadlocks parallel runs.
    static func withLockedHandler<R>(
        _ handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data),
        performing body: () async throws -> R
    ) async rethrows -> R {
        await gate.acquire()
        requestHandler.withLock { $0 = handler }
        do {
            let result = try await body()
            requestHandler.withLock { $0 = nil }
            await gate.release()
            return result
        } catch {
            requestHandler.withLock { $0 = nil }
            await gate.release()
            throw error
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let handler = Self.requestHandler.withLock { $0 }
        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private actor HandlerGate {
    private var isHeld = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isHeld else {
            isHeld = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func release() {
        if waiters.isEmpty {
            isHeld = false
        } else {
            waiters.removeFirst().resume()
        }
    }
}

enum MockURLSessionFactory {
    static func make() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
