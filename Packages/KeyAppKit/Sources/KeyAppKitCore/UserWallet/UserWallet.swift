// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

// TODO: Make privates property.

/// The structure describes user wallet in application level.
/// Each wallet has seed phrase as central property and identifier.
public struct UserWallet: Identifiable, Hashable, Equatable {
    /// Seed phrase for current wallet. Other key pairs is normally will be extracted by this seed phrase.
    public let seedPhrase: [String]?

    /// The selected derivable path for current wallet.
    public let derivablePath: DerivablePath?

    /// The username for current Solana account (base on derivable path)
    public let name: String?

    /// The Solana account (base on derivable path)
    public let account: KeyPair

    /// Torus (web3auth) ethereum address.
    public let ethAddress: String?

    /// Moonpay external client id for identifying user's moonpay buy & sell transactions.
    public let moonpayExternalClientId: String?

    /// Default ethereum wallet keypair for bridge service.
    /// The value was derived from the seed phrase.
    public let ethereumKeypair: EthereumKeyPair

    public init(
        seedPhrase: [String]?,
        derivablePath: DerivablePath?,
        name: String?,
        ethAddress: String?,
        account: KeyPair,
        moonpayExternalClientId: String?,
        ethereumKeypair: EthereumKeyPair
    ) {
        self.seedPhrase = seedPhrase
        self.derivablePath = derivablePath
        self.name = name
        self.ethAddress = ethAddress
        self.account = account
        self.moonpayExternalClientId = moonpayExternalClientId
        self.ethereumKeypair = ethereumKeypair
    }

    public var id: String {
        account.publicKey.base58EncodedString
    }
}
