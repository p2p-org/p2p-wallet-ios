// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol SolendCache {
    func write<T: Codable>(_ value: T, for key: String)
    func read<T: Codable>(type: T.Type, _ key: String) -> T?
    func delete(_ key: String)
}

class SolendInMemoryCache: SolendCache {
    
    private var storage: [String: Any] = .init()

    func write<T>(_ value: T, for key: String) where T: Decodable, T: Encodable {
        storage[key] = value
    }

    func read<T>(type: T.Type, _ key: String) -> T? where T: Decodable, T: Encodable {
        storage[key] as? T
    }

    func delete(_ key: String) {
        storage.removeValue(forKey: key)
    }
}
