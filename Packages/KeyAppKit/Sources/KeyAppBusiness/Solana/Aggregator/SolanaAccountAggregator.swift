// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift

final class SolanaAccountsAggregator: DataAggregator {
    func transform(input: (accounts: [SolanaAccount], fiat: String, prices: [Token: CurrentPrice?]))
    -> [SolanaAccount] {
        let (accounts, fiat, prices) = input

        let output = accounts.map { account in
            var account = account
            let token = account.data.token

            if let price = prices[token] {
                let value: Decimal?
                if let priceValue = price?.value {
                    value = Decimal(floatLiteral: priceValue)
                } else {
                    value = nil
                }

                account.price = TokenPrice(currencyCode: fiat, value: value, token: token)

                // Legacy code
                account.data.price = price
            }

            return account
        }

        return output
    }
}
