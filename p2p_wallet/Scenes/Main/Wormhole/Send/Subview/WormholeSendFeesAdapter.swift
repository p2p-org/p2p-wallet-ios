//
//  WormholeSendFeesAdapter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Send
import Wormhole

struct WormholeSendFeesAdapter: Equatable {
    struct Output: Equatable {
        let crypto: String
        let fiat: String
    }

    private let adapter: WormholeSendInputStateAdapter

    var recipientAddress: String {
        adapter.input?.recipient ?? ""
    }

    /// Actually receive amount for user B.
    var receiveAmount: (CryptoAmount, CurrencyAmount?)? {
        if
            let input = adapter.input,
            let output = adapter.output
        {
            if let arbiterFee = output.fees.arbiter {
                let cryptoFee = arbiterFee.asCryptoAmount
                let currencyFee = arbiterFee.asCurrencyAmount

                // Fee is greater than input. We return zero values.
                if input.amount < cryptoFee {
                    return (CryptoAmount(token: input.amount.token), CurrencyAmount(usd: 0))
                }

                let actuallyReceiveCryptoAmount: CryptoAmount = input.amount - cryptoFee
                let actuallyReceiveCurrencyAmount: CurrencyAmount?

                // Check fiat is available
                if
                    let price = input.solanaAccount.price,
                    let transferAmountInFiat = try? input.amount.toFiatAmount(price: price)
                {
                    actuallyReceiveCurrencyAmount = transferAmountInFiat - arbiterFee.asCurrencyAmount
                } else {
                    actuallyReceiveCurrencyAmount = nil
                }

                return (
                    actuallyReceiveCryptoAmount,
                    actuallyReceiveCurrencyAmount
                )
            } else {
                // Arbiter fee is not available
                if let price = input.solanaAccount.price {
                    return (input.amount, try? input.amount.toFiatAmount(price: price))
                } else {
                    return (input.amount, nil)
                }
            }
        } else {
            // Nothing is available
            return nil
        }
    }

    /// Actually formatted receive amount for user B.
    var receive: Output {
        if let receiveAmount {
            let cryptoFormatter = CryptoFormatter()
            let currencyFormatter = CurrencyFormatter()

            if let currencyAmount = receiveAmount.1 {
                // Fiat is available
                return .init(
                    crypto: cryptoFormatter.string(amount: receiveAmount.0),
                    fiat: currencyFormatter.string(amount: currencyAmount)
                )
            } else {
                // Fiat isn't available
                return .init(
                    crypto: cryptoFormatter.string(amount: receiveAmount.0),
                    fiat: ""
                )
            }
        } else {
            return .init(crypto: "", fiat: "")
        }
    }

    let networkFee: Output?

    let bridgeFee: Output?

    let arbiterFee: Output?

    let messageFee: Output?

    let total: Output?

    init(state: WormholeSendInputState) {
        adapter = .init(state: state)

        networkFee = Self.resolve(amount: adapter.output?.fees.networkFee)
        bridgeFee = Self.resolve(amount: adapter.output?.fees.bridgeFee)
        arbiterFee = Self.resolve(amount: adapter.output?.fees.arbiter)
        messageFee = Self.resolve(amount: adapter.output?.fees.messageAccountRent)

        guard let output = adapter.output else {
            total = nil
            return
        }

        let fees = [
            output.fees.networkFee,
            output.fees.bridgeFee,
            output.fees.arbiter,
            output.fees.messageAccountRent,
        ]
            .compactMap { $0 }

        /// Calculate total fee in crypto
        let feesByToken = Dictionary(grouping: fees, by: \.token)
        let totalCryptoFee: String = feesByToken.values.map { tokenAmounts -> String? in
            guard let initialCryptoAmount = tokenAmounts.first?.asCryptoAmount.with(amount: 0) else {
                return nil
            }

            let cryptoFormatter = CryptoFormatter()
            let totalCryptoAmount = tokenAmounts.map(\.asCryptoAmount).reduce(initialCryptoAmount, +)
            return cryptoFormatter.string(amount: totalCryptoAmount)
        }
        .compactMap { $0 }
        .joined(separator: "\n")

        // Calculate total fee in currency
        let currencyFormatter = CurrencyFormatter()
        let totalCurrencyFee = currencyFormatter.string(amount: output.fees.totalInFiat)

        total = .init(
            crypto: totalCryptoFee,
            fiat: totalCurrencyFee
        )
    }

    private static func resolve(amount: Wormhole.TokenAmount?) -> Output? {
        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        if let amount {
            return .init(
                crypto: cryptoFormatter.string(amount: amount),
                fiat: currencyFormatter.string(amount: amount)
            )
        } else {
            return nil
        }
    }
}
