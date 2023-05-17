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
        if let resultAmount = adapter.output?.fees.recipientGetsAmount {
            
            // Ignore 0 case
            if resultAmount.asCryptoAmount.value == 0 {
                return nil
            }

            return (resultAmount.asCryptoAmount, resultAmount.asCurrencyAmount)
        } else {
            // Nothing is available
            return nil
        }
    }

    /// Actually formatted receive amount for user B.
    var receive: Output? {
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
            return nil
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
        total = nil
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
