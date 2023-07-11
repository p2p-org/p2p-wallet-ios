// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift

final class SolanaAccountsAggregator: DataAggregator {
    func transform(input: (accounts: [SolanaAccount], prices: [SomeToken: TokenPrice?]))
    -> [SolanaAccount] {
        let (accounts, prices) = input

        let output = accounts.map { account in
            var account = account

            if let price = prices[account.token.asSomeToken] {
                account.price = price
            }

            return account
        }

        return output
    }
}
