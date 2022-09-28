// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension KeychainStorage: NameStorageType {
    func save(name: String) {
        if name.isEmpty {
            localKeychain.delete(nameKey)
        } else {
            localKeychain.set(name, forKey: nameKey)
            saveNameToICloudIfAccountSaved()
            onValueChangeSubject.on(.next(("getName", name)))
        }
    }

    func getName() -> String? {
        localKeychain.get(nameKey)
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
    func saveAttempt(_ attempt: Int) {
        localKeychain.set(String(attempt), forKey: pincodeAttemptsKey)
    }

    var attempt: Int? {
        Int(localKeychain.get(pincodeAttemptsKey) ?? "")
    }

    func save(_ pinCode: String) {
        localKeychain.set(pinCode, forKey: pincodeKey)
        saveAttempt(0)
    }

    var pinCode: String? {
        localKeychain.get(pincodeKey)
    }
}

extension KeychainStorage: PincodeSeedPhrasesStorage {
    var phrases: [String]? { account?.phrase }
}
