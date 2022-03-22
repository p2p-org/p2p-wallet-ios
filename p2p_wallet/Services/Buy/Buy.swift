//
// Created by Giang Long Tran on 14.02.2022.
//

import Foundation

struct Buy {
    typealias ProcessingService = BuyProcessingServiceType
    typealias ExchangeService = BuyExchangeServiceType
    typealias Currency = BuyCurrencyType

    enum FiatCurrency: String, BuyCurrencyType {
        case usd

        func toString() -> String { rawValue }
    }

    enum CryptoCurrency: String, BuyCurrencyType {
        case eth
        case sol
        case usdc

        func toString() -> String { rawValue }

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

        // TODO: move code to moonpay domain
        var code: String {
            switch self {
            case .eth:
                return "eth"
            case .sol:
                return "sol"
            case .usdc:
                return "usdc_sol"
            }
        }

        var tokenName: String {
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
