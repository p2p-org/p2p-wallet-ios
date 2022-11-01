// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

extension KeychainStorage: AccountStorageType {
    public var account: SolanaSwift.Account? {
        _account
    }

    var deviceShare: String? {
        localKeychain.get(deviceShareKey)
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
            _account = try await SolanaSwift.Account(
                phrase: phrases,
                network: Defaults.apiEndPoint.network,
                derivablePath: derivablePath
            )
        } else {
            _account = SolanaSwift.Account(
                phrase: [],
                publicKey: try .init(string: GlobalAppState.shared.forcedWalletAddress),
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

    func getDerivablePath() -> DerivablePath? {
        guard
            let derivableTypeRaw = localKeychain.get(derivableTypeKey),
            let derivableType = DerivablePath.DerivableType(rawValue: derivableTypeRaw)
        else { return nil }

        let walletIndexRaw = localKeychain.get(walletIndexKey)
        let walletIndex = Int(walletIndexRaw ?? "0")

        return .init(type: derivableType, walletIndex: walletIndex ?? 0)
    }

    func save(derivableType: DerivablePath.DerivableType) throws {
        localKeychain.set(derivableType.rawValue, forKey: derivableTypeKey)
        _account = nil
    }

    public func save(_: SolanaSwift.Account) throws { fatalError("Method has not been implemented") }

    func clearAccount() {
        removeCurrentAccount()
    }

    func save(deviceShare: String) throws {
        if deviceShare.isEmpty {
            localKeychain.delete(deviceShareKey)
        } else {
            localKeychain.set(deviceShare, forKey: deviceShareKey)
        }
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
