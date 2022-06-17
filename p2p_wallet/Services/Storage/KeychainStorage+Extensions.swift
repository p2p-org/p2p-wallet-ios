// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension KeychainStorage: NameStorageType {
    func save(name: String) {
        keychain.set(name, forKey: nameKey)
        saveNameToICloudIfAccountSaved()
        onValueChangeSubject.on(.next(("getName", name)))
    }

    func getName() -> String? {
        keychain.get(nameKey)
    }

    private func saveNameToICloudIfAccountSaved() {
        if let account = accountFromICloud()?.first(where: { $0.phrase.components(separatedBy: " ") == phrases }) {
            let account = RawAccount(
                name: getName(),
                phrase: account.phrase,
                derivablePath: account.derivablePath
            )
            _ = saveToICloud(account: account)
        }
    }
}

extension KeychainStorage: PincodeStorageType {
    func save(_ pinCode: String) {
        keychain.set(pinCode, forKey: pincodeKey)
    }

    var pinCode: String? {
        keychain.get(pincodeKey)
    }
}

extension KeychainStorage: PincodeSeedPhrasesStorage {
    var phrases: [String]? { account?.phrase }
}
