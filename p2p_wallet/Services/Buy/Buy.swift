//
// Created by Giang Long Tran on 14.02.2022.
//

import CryptoKit
import Foundation
import SolanaSwift
import SwiftyUserDefaults

struct Buy {
    typealias ProcessingService = BuyProcessingServiceType
    typealias ExchangeService = BuyExchangeServiceType
    typealias Currency = BuyCurrencyType

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

        var mintAddress: String {
            guard let mintAddress = CryptoCurrency.addresses[Defaults.apiEndPoint.network]?[self] else {
                assert(true, "Unhandeled mint address for \(Defaults.apiEndPoint.network) : \(self)")
                return ""
            }
            return mintAddress
        }

        static var addresses: [Network: [CryptoCurrency: String]] = [
            .mainnetBeta: [
                .usdc: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
                .eth: "2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk",
                .sol: PublicKey.wrappedSOLMint.base58EncodedString,
            ],
            .testnet: [
                .usdc: "CpMah17kQEL2wqyMKt3mZBdTnZbkbfx4nqmQMFDP5vwp",
//                .eth: "",
                .sol: PublicKey.wrappedSOLMint.base58EncodedString,
            ],
            .devnet: [
                .usdc: "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
                .eth: "Ff5JqsAYUD4vAfQUtfRprT4nXu9e28tTBZTDFMnJNdvd",
                .sol: PublicKey.wrappedSOLMint.base58EncodedString,
            ],
        ]
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
