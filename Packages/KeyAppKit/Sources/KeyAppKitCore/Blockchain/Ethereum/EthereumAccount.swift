import BigInt
import Foundation

public struct EthereumAccount: Equatable {
    public let address: String
    public let token: EthereumToken
    public let balance: BigUInt
    public var price: TokenPrice?

    public init(address: String, token: EthereumToken, balance: BigUInt, price: TokenPrice? = nil) {
        self.address = address
        self.token = token
        self.balance = balance
        self.price = price
    }

    /// Convert balance into user-friendly format by using decimals.
    public var representedBalance: CryptoAmount {
        .init(
            amount: balance,
            token: token
        )
    }

    /// Balance in fiat
    public var balanceInFiat: CurrencyAmount? {
        guard let price else {
            return nil
        }

        let rate = price.value

        return .init(
            value: representedBalance.amount * rate,
            currencyCode: price.currencyCode
        )
    }
}
