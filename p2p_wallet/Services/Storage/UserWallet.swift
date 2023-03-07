// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import KeyAppBusiness
import Resolver
import SolanaSwift

struct UserWallet: Identifiable, Hashable, Equatable {
    /// Seed phrase for current wallet. Other keypairs is normally will be extracted by this seed phrase.
    let seedPhrase: [String]?

    /// The derivable path for current wallet.
    let derivablePath: DerivablePath?

    /// Username
    let name: String?

    /// Solana account
    let account: KeyPair

    /// Torus device share
    let deviceShare: String?

    /// Torus ethereum address
    let ethAddress: String?

    /// Moonpay external client id for identifyting user's moonpay buy & sell transactions.
    let moonpayExternalClientId: String?

    let ethereumKeypair: EthereumKeyPair

    init(
        seedPhrase: [String]?,
        derivablePath: DerivablePath?,
        name: String?,
        deviceShare: String?,
        ethAddress: String?,
        account: KeyPair,
        moonpayExternalClientId: String?,
        ethereumKeypair: EthereumKeyPair
    ) {
        self.seedPhrase = seedPhrase
        self.derivablePath = derivablePath
        self.name = name
        self.deviceShare = deviceShare
        self.ethAddress = ethAddress

        self.account = account
        self.moonpayExternalClientId = moonpayExternalClientId
        self.ethereumKeypair = ethereumKeypair
    }

    var id: String {
        account.publicKey.base58EncodedString
    }
}
