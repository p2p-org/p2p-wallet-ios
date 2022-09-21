// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension KeychainStorage: NameStorageType {
    func save(name: String) {
        if name.isEmpty {
            icloudKeychain.delete(nameKey)
        } else {
            icloudKeychain.set(name, forKey: nameKey)
            saveNameToICloudIfAccountSaved()
            onValueChangeSubject.on(.next(("getName", name)))
        }
    }

    func getName() -> String? {
        icloudKeychain.get(nameKey)
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
        icloudKeychain.set(String(attempt), forKey: pincodeAttemptsKey)
    }

    var attempt: Int? {
        Int(icloudKeychain.get(pincodeAttemptsKey) ?? "")
    }

    func save(_ pinCode: String) {
        icloudKeychain.set(pinCode, forKey: pincodeKey)
        saveAttempt(0)
    }

    var pinCode: String? {
        icloudKeychain.get(pincodeKey)
    }
}

extension KeychainStorage: PincodeSeedPhrasesStorage {
    var phrases: [String]? { account?.phrase }
}
