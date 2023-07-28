// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitCore
import SolanaSwift

public struct UserWalletEnvironments: Equatable {
    let wallets: [SolanaAccount]
    let ethereumAccount: String?

    let exchangeRate: [String: TokenPrice]
    let tokens: Set<TokenMetadata>

    let rentExemptionAmountForWalletAccount: Lamports
    let rentExemptionAmountForSPLAccount: Lamports

    public init(
        wallets: [SolanaAccount],
        ethereumAccount: String?,
        exchangeRate: [String: TokenPrice],
        tokens: Set<TokenMetadata>,
        rentExemptionAmountForWalletAccount: Lamports = 890_880,
        rentExemptionAmountForSPLAccount: Lamports = 2_039_280
    ) {
        self.wallets = wallets
        self.ethereumAccount = ethereumAccount
        self.exchangeRate = exchangeRate
        self.tokens = tokens
        self.rentExemptionAmountForWalletAccount = rentExemptionAmountForWalletAccount
        self.rentExemptionAmountForSPLAccount = rentExemptionAmountForSPLAccount
    }

    public static var empty: Self {
        .init(wallets: [], ethereumAccount: nil, exchangeRate: [:], tokens: [])
    }

    public func copy(tokens: Set<TokenMetadata>? = nil) -> Self {
        .init(
            wallets: wallets,
            ethereumAccount: ethereumAccount,
            exchangeRate: exchangeRate,
            tokens: tokens ?? self.tokens,
            rentExemptionAmountForWalletAccount: rentExemptionAmountForWalletAccount,
            rentExemptionAmountForSPLAccount: rentExemptionAmountForSPLAccount
        )
    }
}
