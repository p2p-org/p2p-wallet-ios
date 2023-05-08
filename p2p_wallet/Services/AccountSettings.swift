// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Combine

protocol AccountSettingsProvider {
    func write<T: Codable>(key: String, value: T?)
    func read<T: Codable>(key: String) -> T?
}

struct AccountSettingsUserDefaultsProvider: AccountSettingsProvider {
    func write<T: Codable>(key: String, value: T?) {
        if let value = value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func read<T: Codable>(key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }
}

class AccountSettings: ObservableObject {
    let provider: AccountSettingsProvider

    @Published var deleteWeb3AuthRequest: Date? {
        didSet { provider.write(key: "deleteWeb3AuthRequest", value: deleteWeb3AuthRequest) }
    }

    init(provider: AccountSettingsProvider) {
        self.provider = provider

        self.deleteWeb3AuthRequest = provider.read(key: "deleteWeb3AuthRequest")
    }

    func reset() {
        deleteWeb3AuthRequest = nil
    }
}
