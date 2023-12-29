import CryptoKit
import Foundation
import SolanaSwift
import SwiftyUserDefaults

enum Buy {
    typealias Currency = BuyCurrencyType

    enum FiatCurrency: String, BuyCurrencyType, Equatable {
        case usd
        case eur
        case cny
        case vnd
        case rub
        case gbp

        var name: String {
            switch self {
            case .usd:
                return "USD"
            case .eur:
                return "EUR"
            case .cny:
                return "CNY"
            case .vnd:
                return "VND"
            case .rub:
                return "RUB"
            case .gbp:
                return "GBP"
            }
        }
    }

    enum CryptoCurrency: String, BuyCurrencyType, Equatable {
        case eth
        case sol
        case usdc

        var name: String {
            switch self {
            case .eth:
                return "ETH"
            case .sol:
                return "SOL"
            case .usdc:
                return "USDC"
            }
        }
    }

    struct ExchangeInput {
        let amount: Double
        let currency: Currency
    }

    struct ExchangeOutput {
        let amount: Double
        let currency: Currency

        let processingFee: Double
        let networkFee: Double
        let purchaseCost: Double

        let total: Double
    }

    struct ExchangeRate {
        let amount: Double
        let cryptoCurrency: CryptoCurrency
        let fiatCurrency: FiatCurrency
    }

    enum Exception: Error {
        case invalidInput
    }
}

protocol BuyCurrencyType {
    func isEqualTo(_ other: BuyCurrencyType) -> Bool
}

extension BuyCurrencyType where Self: Equatable {
    func isEqualTo(_ other: BuyCurrencyType) -> Bool {
        guard let otherX = other as? Self else { return false }
        return self == otherX
    }
}
