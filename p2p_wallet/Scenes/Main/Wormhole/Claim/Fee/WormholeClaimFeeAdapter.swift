//
//  WormholeClaimFeeAdapter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 27.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

struct WormholeClaimFeeAdapter {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    let receive: Amount

    let networkFee: Amount

    let accountCreationFee: Amount?

    let wormholeBridgeAndTrxFee: Amount

    init(
        receive: Amount,
        networkFee: Amount,
        accountCreationFee: Amount?,
        wormholeBridgeAndTrxFee: Amount
    ) {
        self.receive = receive
        self.networkFee = networkFee
        self.accountCreationFee = accountCreationFee
        self.wormholeBridgeAndTrxFee = wormholeBridgeAndTrxFee
    }

    init(account: EthereumAccount, bundle: WormholeBundle?) {
        guard let bundle else {
            receive = ("", "", false)
            networkFee = ("", "", false)
            accountCreationFee = nil
            wormholeBridgeAndTrxFee = ("", "", false)
            return
        }

        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        receive = (
            cryptoFormatter.string(amount: bundle.resultAmount),
            currencyFormatter.string(for: account.balanceInFiat) ?? "",
            false
        )

        if bundle.compensationDeclineReason == nil {
            networkFee = (L10n.paidByKeyApp, L10n.free, true)
            accountCreationFee = (L10n.paidByKeyApp, L10n.free, true)
            wormholeBridgeAndTrxFee = (L10n.paidByKeyApp, L10n.free, true)
        } else {
            // Network fee
            networkFee = (
                cryptoFormatter.string(amount: bundle.fees.gas),
                currencyFormatter.string(amount: bundle.fees.gas),
                false
            )

            // Create accounts fee
            if let createAccount = bundle.fees.createAccount {
                accountCreationFee = (
                    cryptoFormatter.string(amount: createAccount),
                    currencyFormatter.string(amount: createAccount),
                    false
                )
            } else {
                accountCreationFee = nil
            }

            // Network fee
            wormholeBridgeAndTrxFee = (
                cryptoFormatter.string(amount: bundle.fees.arbiter),
                currencyFormatter.string(amount: bundle.fees.arbiter),
                false
            )
        }
    }
}
