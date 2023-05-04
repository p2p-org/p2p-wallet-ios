//
//  File.swift
//
//
//  Created by Giang Long Tran on 05.05.2023.
//

import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift

class SolanaAccountsAggregator: DataAggregator {
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

                account.price = .init(currencyCode: fiat, value: value, token: token)
                
                // Legacy code
                account.data.price = price
            }

            return account
        }

        return output
    }
}
