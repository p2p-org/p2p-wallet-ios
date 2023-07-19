// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeychainSwift

extension KeychainStorage {
    func saveToICloud(account: RawAccount) -> Bool {
        var accountsToSave = [account]

        if var currentAccounts = accountFromICloud() {
            // if account exists
            if let index = currentAccounts
                .firstIndex(where: { $0.phrase == account.phrase && $0.derivablePath == account.derivablePath })
            {
                currentAccounts[index] = account
            }
            // new account
            else {
                currentAccounts.append(account)
            }
            accountsToSave = currentAccounts
        }

        // save
        if let data = try? JSONEncoder().encode(accountsToSave) {
            let icloudKeychain = KeychainSwift()
            icloudKeychain.synchronizable = true

            return icloudKeychain.set(data, forKey: iCloudAccountsKey, withAccess: .accessibleAfterFirstUnlock)
        }
        return false
    }

    func accountFromICloud() -> [RawAccount]? {
        let icloudKeychain = KeychainSwift()
        icloudKeychain.synchronizable = true

        guard let data = icloudKeychain.getData(iCloudAccountsKey) else { return nil }
        return try? JSONDecoder().decode([RawAccount].self, from: data)
    }
}
