// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Resolver
import SolanaSwift

struct UserWallet: Identifiable, Hashable, Equatable {
    let seedPhrase: [String]?
    let derivablePath: DerivablePath?
    let name: String?

    /// Solana account
    let account: Account

    // TKey part
    let deviceShare: String?
    let ethAddress: String?

    init(
        seedPhrase: [String]?,
        derivablePath: DerivablePath?,
        name: String?,
        deviceShare: String?,
        ethAddress: String?,
        account: Account
    ) {
        self.seedPhrase = seedPhrase
        self.derivablePath = derivablePath
        self.name = name
        self.deviceShare = deviceShare
        self.ethAddress = ethAddress

        self.account = account
    }

    var id: String {
        account.publicKey.base58EncodedString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(seedPhrase)
        hasher.combine(derivablePath)
        hasher.combine(name)
        hasher.combine(account)
        hasher.combine(deviceShare)
        hasher.combine(ethAddress)
    }

    static func == (lhs: UserWallet, rhs: UserWallet) -> Bool {
        if lhs.seedPhrase != rhs.seedPhrase { return false }
        if lhs.derivablePath != rhs.derivablePath { return false }
        if lhs.name != rhs.name { return false }
        if lhs.account != rhs.account { return false }
        if lhs.deviceShare != rhs.deviceShare { return false }
        if lhs.ethAddress != rhs.ethAddress { return false }
        return true
    }
}
