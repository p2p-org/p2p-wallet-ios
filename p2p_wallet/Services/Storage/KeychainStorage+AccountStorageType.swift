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
        icloudKeychain.get(deviceShareKey)
    }

    var derivablePath: DerivablePath {
        let derivableTypeRaw = icloudKeychain.get(derivableTypeKey) ?? ""
        let walletIndexRaw = icloudKeychain.get(walletIndexKey) ?? ""
        let defaultDerivablePath = DerivablePath.default
        let derivableType = DerivablePath.DerivableType(rawValue: derivableTypeRaw) ?? defaultDerivablePath.type
        let walletIndex = Int(walletIndexRaw) ?? defaultDerivablePath.walletIndex

        return .init(type: derivableType, walletIndex: walletIndex)
    }

    func reloadSolanaAccount() async throws {
        guard let phrases = icloudKeychain.get(phrasesKey)?.components(separatedBy: " ") else { return }
        _account = try await SolanaSwift.Account(
            phrase: phrases,
            network: Defaults.apiEndPoint.network,
            derivablePath: derivablePath
        )
    }

    func save(phrases: [String]) throws {
        icloudKeychain.set(phrases.joined(separator: " "), forKey: phrasesKey)
        _account = nil
    }

    func save(walletIndex: Int) throws {
        icloudKeychain.set("\(walletIndex)", forKey: walletIndexKey)
        _account = nil
    }

    func getDerivablePath() -> DerivablePath? {
        guard
            let derivableTypeRaw = icloudKeychain.get(derivableTypeKey),
            let derivableType = DerivablePath.DerivableType(rawValue: derivableTypeRaw)
        else { return nil }

        let walletIndexRaw = icloudKeychain.get(walletIndexKey)
        let walletIndex = Int(walletIndexRaw ?? "0")

        return .init(type: derivableType, walletIndex: walletIndex ?? 0)
    }

    func save(derivableType: DerivablePath.DerivableType) throws {
        icloudKeychain.set(derivableType.rawValue, forKey: derivableTypeKey)
        _account = nil
    }

    public func save(_: SolanaSwift.Account) throws { fatalError("Method has not been implemented") }

    func clearAccount() {
        removeCurrentAccount()
    }

    func save(deviceShare: String) throws {
        if deviceShare.isEmpty {
            localKeychain.delete(deviceShare)
        } else {
            localKeychain.set(deviceShare, forKey: deviceShareKey)
        }
    }

    var ethAddress: String? {
        icloudKeychain.get(ethAddressKey)
    }

    func save(ethAddress: String) throws {
        if ethAddress.isEmpty {
            icloudKeychain.delete(ethAddressKey)
        } else {
            icloudKeychain.set(ethAddress, forKey: ethAddressKey)
        }
    }
}
