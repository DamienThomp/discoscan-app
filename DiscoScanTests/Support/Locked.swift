//
//  Locked.swift
//  DiscoScanTests
//

import Synchronization

/// Copyable owner for a `Mutex`. `Mutex` itself cannot be captured by an escaping closure.
final class Locked<Value: Sendable>: Sendable {
    private let mutex: Mutex<Value>

    init(_ initialValue: sending Value) {
        mutex = Mutex(initialValue)
    }

    func withLock<R: Sendable>(_ body: (inout sending Value) -> sending R) -> sending R {
        mutex.withLock(body)
    }
}
