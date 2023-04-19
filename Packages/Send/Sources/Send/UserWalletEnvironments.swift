// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaPricesAPIs
import SolanaSwift

public struct UserWalletEnvironments: Equatable {
    let wallets: [Wallet]
    let ethereumAccount: String?

    let exchangeRate: [String: CurrentPrice]
    let tokens: Set<Token>

    let rentExemptionAmountForWalletAccount: Lamports
    let rentExemptionAmountForSPLAccount: Lamports

    public init(
        wallets: [Wallet],
        ethereumAccount: String?,
        exchangeRate: [String: CurrentPrice],
        tokens: Set<Token>,
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

    public func copy(tokens: Set<Token>? = nil) -> Self {
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
