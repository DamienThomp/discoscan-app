//
//  DiscogsDecoding.swift
//  DiscoScan
//

import Foundation

extension KeyedDecodingContainer {
    func decodeDiscogsURL(forKey key: Key) -> URL? {
        guard let string = try? decodeIfPresent(String.self, forKey: key),
              !string.isEmpty else {
            return nil
        }
        return URL(string: string)
    }

    func decodeDiscogsArray<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> [T] {
        try decodeIfPresent([T].self, forKey: key) ?? []
    }
}
