//
// Created by Giang Long Tran on 14.02.2022.
//

import Foundation

struct Buy {
    public typealias ProcessingService = BuyProcessingServiceType
    public typealias ExchangeService = BuyExchangeServiceType
    public typealias Currency = BuyCurrencyType

    enum FiatCurrency: BuyCurrencyType {
        case usd

        var name: String {
            switch self {
            case .usd:
                return "USD"
            }
        }
    }

    enum CryptoCurrency: BuyCurrencyType {
        case eth
        case sol
        case usdc

        var fullname: String {
            switch self {
            case .eth:
                return "Ethereum"
            case .sol:
                return "Solana"
            case .usdc:
                return "USD Coin"
            }
        }

        var solanaCode: String {
            switch self {
            case .eth:
                return "eth"
            case .sol:
                return "sol"
            case .usdc:
                return "usdc"
            }
        }

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

        static let all: Set<CryptoCurrency> = [.eth, .sol, .usdc]
    }

    struct ExchangeInput {
        let amount: Double
        let currency: Currency

        func swap(with output: ExchangeOutput) -> (ExchangeInput, ExchangeOutput) {
            (
                .init(amount: output.amount, currency: output.currency),
                .init(
                    amount: amount,
                    currency: currency,
                    processingFee: output.processingFee,
                    networkFee: output.networkFee,
                    purchaseCost: output.purchaseCost,
                    total: output.total
                )
            )
        }
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
        case message(String)
    }
}

protocol BuyCurrencyType {
    var name: String { get }
}
