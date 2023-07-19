// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeychainSwift
import Resolver
import SolanaSwift

class KeychainStorage: StorageType {
    // MARK: - Constants

    let pincodeKey: String
    let pincodeAttemptsKey: String
    let phrasesKey: String
    let derivableTypeKey: String
    let walletIndexKey: String
    let nameKey: String
    let ethAddressKey: String
    let iCloudAccountsKey = "Keychain.Accounts"
    private let iCloudKeychainToLocalKeychainMigrated = "iCloudKeychainToLocalKeychainMigrated"

    // MARK: - Properties

    var _account: KeyPair?

    // MARK: - Services

    /// This keychain storage will only locally store in device
    let localKeychain = KeychainSwift()

    /// This keychain storage for storage metadata
    let metadataKeychain = KeychainSwift(keyPrefix: "metadata_")

    // MARK: - Initializers

    init() {
        if let nameKey = Defaults.keychainNameKey {
            self.nameKey = nameKey
        } else {
            nameKey = UUID().uuidString
            Defaults.keychainNameKey = nameKey
        }

        if
            let pincodeKey = Defaults.keychainPincodeKey,
            let pincodeAttemptsKey = Defaults.pincodeAttemptsKey,
            let phrasesKey = Defaults.keychainPhrasesKey,
            let derivableTypeKey = Defaults.keychainDerivableTypeKey,
            let walletIndexKey = Defaults.keychainWalletIndexKey,
            let ethAddressKey = Defaults.keychainEthAddressKey
        {
            self.pincodeKey = pincodeKey
            self.pincodeAttemptsKey = pincodeAttemptsKey
            self.phrasesKey = phrasesKey
            self.derivableTypeKey = derivableTypeKey
            self.walletIndexKey = walletIndexKey
            self.ethAddressKey = ethAddressKey
        } else if
            let pincodeKey = Defaults.keychainPincodeKey,
            let phrasesKey = Defaults.keychainPhrasesKey,
            let derivableTypeKey = Defaults.keychainDerivableTypeKey,
            let walletIndexKey = Defaults.keychainWalletIndexKey,
            !UserDefaults.standard.bool(forKey: iCloudKeychainToLocalKeychainMigrated)
        {
            self.pincodeKey = pincodeKey
            self.phrasesKey = phrasesKey
            self.derivableTypeKey = derivableTypeKey
            self.walletIndexKey = walletIndexKey

            pincodeAttemptsKey = UUID().uuidString
            Defaults.pincodeAttemptsKey = pincodeAttemptsKey

            ethAddressKey = UUID().uuidString
            Defaults.keychainEthAddressKey = ethAddressKey
        } else {
            let pincodeKey = UUID().uuidString
            self.pincodeKey = pincodeKey
            Defaults.keychainPincodeKey = pincodeKey

            let pincodeAttemptsKey = UUID().uuidString
            self.pincodeAttemptsKey = pincodeAttemptsKey
            Defaults.pincodeAttemptsKey = pincodeAttemptsKey

            let phrasesKey = UUID().uuidString
            self.phrasesKey = phrasesKey
            Defaults.keychainPhrasesKey = phrasesKey

            let derivableTypeKey = UUID().uuidString
            self.derivableTypeKey = derivableTypeKey
            Defaults.keychainDerivableTypeKey = derivableTypeKey

            let walletIndexKey = UUID().uuidString
            self.walletIndexKey = walletIndexKey
            Defaults.keychainWalletIndexKey = walletIndexKey

            let ethAddressKey = UUID().uuidString
            self.ethAddressKey = ethAddressKey
            Defaults.keychainEthAddressKey = ethAddressKey

            removeCurrentAccount()
        }

        migrate()
    }

    // MARK: - Migration

    func migrate() {
        let icloudKeychain = KeychainSwift()
        icloudKeychain.synchronizable = true

        // migrate iCloud storage from NSUbiquitousKeyValueStore to keychain
        let ubiquitousKeyValueStoreToKeychain = "UbiquitousKeyValueStoreToKeychain"
        if !UserDefaults.standard.bool(forKey: ubiquitousKeyValueStoreToKeychain) {
            let ubiquitousStore = NSUbiquitousKeyValueStore()
            if let data = ubiquitousStore.data(forKey: iCloudAccountsKey) {
                icloudKeychain.set(data, forKey: iCloudAccountsKey)
            }
            // mark as completed
            UserDefaults.standard.set(true, forKey: ubiquitousKeyValueStoreToKeychain)
        }

        // migrate from iCloud keychain to localKeychain
        if !UserDefaults.standard.bool(forKey: iCloudKeychainToLocalKeychainMigrated) {
            // safely check all keys in localKeychain, only override when data in localKeychain is empty
            if localKeychain.getData(pincodeKey) == nil,
               localKeychain.getData(pincodeAttemptsKey) == nil,
               localKeychain.getData(phrasesKey) == nil,
               localKeychain.getData(derivableTypeKey) == nil,
               localKeychain.getData(walletIndexKey) == nil,
               localKeychain.getData(ethAddressKey) == nil
            {
                [pincodeKey, phrasesKey, derivableTypeKey, walletIndexKey].forEach { key in
                    guard let data = icloudKeychain.getData(key) else { return }
                    localKeychain.set(data, forKey: key)
                }
            }

            // mark as completed
            UserDefaults.standard.set(true, forKey: iCloudKeychainToLocalKeychainMigrated)
        }
    }

    func removeCurrentAccount() {
        localKeychain.delete(pincodeKey)
        localKeychain.delete(phrasesKey)
        localKeychain.delete(derivableTypeKey)
        localKeychain.delete(walletIndexKey)
        localKeychain.delete(nameKey)
        localKeychain.delete(pincodeAttemptsKey)

        removeAccountCache()
        Resolver.resolve(UserSessionCache.self).clear()
    }

    private func removeAccountCache() {
        _account = nil
    }
}
