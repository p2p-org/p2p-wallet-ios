// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeychainSwift
import RxCocoa
import RxSwift
import SolanaSwift

class KeychainStorage {
    // MARK: - Constants

    let onValueChangeSubject = PublishSubject<StorageValueOnChange>()
    let pincodeKey: String
    let pincodeAttemptsKey: String
    let phrasesKey: String
    let derivableTypeKey: String
    let walletIndexKey: String
    let nameKey: String
    let ethAddressKey: String

    let deviceShareKey: String = "deviceShareKey"

    let iCloudAccountsKey = "Keychain.Accounts"

    // MARK: - Properties

    var _account: SolanaSwift.Account?

    // MARK: - Services

    /// This keychain storage will sync across devices
    let icloudKeychain: KeychainSwift = {
        let kc = KeychainSwift()
        kc.synchronizable = true
        return kc
    }()

    /// This keychain storage will only locally store in device
    let localKeychain: KeychainSwift = .init()

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
    }

    func removeCurrentAccount() {
        icloudKeychain.delete(pincodeKey)
        icloudKeychain.delete(phrasesKey)
        icloudKeychain.delete(derivableTypeKey)
        icloudKeychain.delete(walletIndexKey)
        icloudKeychain.delete(nameKey)
        icloudKeychain.delete(pincodeAttemptsKey)

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
