import Foundation
import KeyAppKitCore
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
