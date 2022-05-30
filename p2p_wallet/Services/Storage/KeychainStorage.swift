// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeychainSwift
import RxCocoa
import RxSwift

class KeychainStorage {
    // MARK: - Constants

    let onValueChangeSubject = PublishSubject<StorageValueOnChange>()
    let pincodeKey: String
    let phrasesKey: String
    let derivableTypeKey: String
    let walletIndexKey: String
    let nameKey: String

    let iCloudAccountsKey = "Keychain.Accounts"

    // MARK: - Properties

    var _account: SolanaSwift.Account?

    // MARK: - Services

    let keychain: KeychainSwift = {
        let kc = KeychainSwift()
        kc.synchronizable = true
        return kc
    }()

    // MARK: - Initializers

    init() {
        if let nameKey = Defaults.keychainNameKey {
            self.nameKey = nameKey
        } else {
            nameKey = UUID().uuidString
            Defaults.keychainNameKey = nameKey
        }

        if let pincodeKey = Defaults.keychainPincodeKey,
           let phrasesKey = Defaults.keychainPhrasesKey,
           let derivableTypeKey = Defaults.keychainDerivableTypeKey,
           let walletIndexKey = Defaults.keychainWalletIndexKey
        {
            self.pincodeKey = pincodeKey
            self.phrasesKey = phrasesKey
            self.derivableTypeKey = derivableTypeKey
            self.walletIndexKey = walletIndexKey
        } else {
            let pincodeKey = UUID().uuidString
            self.pincodeKey = pincodeKey
            Defaults.keychainPincodeKey = pincodeKey

            let phrasesKey = UUID().uuidString
            self.phrasesKey = phrasesKey
            Defaults.keychainPhrasesKey = phrasesKey

            let derivableTypeKey = UUID().uuidString
            self.derivableTypeKey = derivableTypeKey
            Defaults.keychainDerivableTypeKey = derivableTypeKey

            let walletIndexKey = UUID().uuidString
            self.walletIndexKey = walletIndexKey
            Defaults.keychainWalletIndexKey = walletIndexKey

            removeCurrentAccount()
        }

        migrate()
    }

    // MARK: - Migration

    func migrate() {
        // migrate iCloud storage from NSUbiquitousKeyValueStore to keychain
        let ubiquitousKeyValueStoreToKeychain = "UbiquitousKeyValueStoreToKeychain"
        if !UserDefaults.standard.bool(forKey: ubiquitousKeyValueStoreToKeychain) {
            let ubiquitousStore = NSUbiquitousKeyValueStore()
            if let data = ubiquitousStore.data(forKey: iCloudAccountsKey) {
                keychain.set(data, forKey: iCloudAccountsKey)
            }
            // mark as completed
            UserDefaults.standard.set(true, forKey: ubiquitousKeyValueStoreToKeychain)
        }
    }

    func removeCurrentAccount() {
        keychain.delete(pincodeKey)
        keychain.delete(phrasesKey)
        keychain.delete(derivableTypeKey)
        keychain.delete(walletIndexKey)
        keychain.delete(nameKey)

        removeAccountCache()
    }

    private func removeAccountCache() {
        _account = nil
    }
}

extension KeychainStorage: StorageType {
    var onValueChange: Signal<StorageValueOnChange> {
        onValueChangeSubject.asSignal(onErrorJustReturn: ("", nil))
    }
}
