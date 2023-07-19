// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

extension KeychainStorage: AccountStorageType {
    public var account: KeyPair? {
        _account
    }

    var derivablePath: DerivablePath {
        let derivableTypeRaw = localKeychain.get(derivableTypeKey) ?? ""
        let walletIndexRaw = localKeychain.get(walletIndexKey) ?? ""
        let defaultDerivablePath = DerivablePath.default
        let derivableType = DerivablePath.DerivableType(rawValue: derivableTypeRaw) ?? defaultDerivablePath.type
        let walletIndex = Int(walletIndexRaw) ?? defaultDerivablePath.walletIndex

        return .init(type: derivableType, walletIndex: walletIndex)
    }

    func reloadSolanaAccount() async throws {
        guard let phrases = localKeychain.get(phrasesKey)?.components(separatedBy: " ") else { return }

        if GlobalAppState.shared.forcedWalletAddress.isEmpty {
            _account = try await KeyPair(
                phrase: phrases,
                network: Defaults.apiEndPoint.network,
                derivablePath: derivablePath
            )
        } else {
            _account = try KeyPair(
                phrase: phrases,
                publicKey: .init(string: GlobalAppState.shared.forcedWalletAddress),
                secretKey: Data()
            )
        }
    }

    func save(phrases: [String]) throws {
        localKeychain.set(phrases.joined(separator: " "), forKey: phrasesKey)
        _account = nil
    }

    func save(walletIndex: Int) throws {
        localKeychain.set("\(walletIndex)", forKey: walletIndexKey)
        _account = nil
    }

    func save(derivableType: DerivablePath.DerivableType) throws {
        localKeychain.set(derivableType.rawValue, forKey: derivableTypeKey)
        _account = nil
    }

    public func save(_: KeyPair) throws { fatalError("Method has not been implemented") }

    func clearAccount() {
        removeCurrentAccount()
    }

    var ethAddress: String? {
        localKeychain.get(ethAddressKey)
    }

    func save(ethAddress: String) throws {
        if ethAddress.isEmpty {
            localKeychain.delete(ethAddressKey)
        } else {
            localKeychain.set(ethAddress, forKey: ethAddressKey)
        }
    }
}
