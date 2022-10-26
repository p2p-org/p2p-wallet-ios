// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Solend

class UserSessionCache {
    let storage = UserDefaults(suiteName: "appSuite")
    
    func write<T: Codable>(_ value: T, for key: String) {
        storage?.set(try? JSONEncoder().encode(value), forKey: key)
    }
    
    func read<T: Codable>(type: T.Type, _ key: String) -> T? {
        guard let data: Data = storage?.value(forKey: key) as? Data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func delete(_ key: String) {
        storage?.removeObject(forKey: key)
    }
    
    func clear() {
        storage?.removeAll()
    }
}

extension UserSessionCache: SolendCache {}
