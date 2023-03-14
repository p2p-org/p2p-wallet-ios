//
//  WormholeClaimFeeModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

/// Data structure for displaying model in ``WormholeClaimView``.
struct WormholeClaimFeeModel {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    let receive: Amount

    let networkFee: Amount?

    let accountCreationFee: Amount?

    let wormholeBridgeAndTrxFee: Amount?
}

extension WormholeClaimFeeModel {
    init(account: EthereumAccountsService.Account, bundle: WormholeBundle?) {
        let cryptoFormatter = CryptoFormatter(prefix: "~")
        let currencyFormatter = CurrencyFormatter()

        self.receive = (
            cryptoFormatter.string(for: account.representedBalance) ?? "N/A",
            currencyFormatter.string(for: account.balanceInFiat) ?? "N/A",
            false
        )

        // Ensure bundle is not nil
        guard let bundle else {
            self.networkFee = nil
            self.accountCreationFee = nil
            self.wormholeBridgeAndTrxFee = nil

            return
        }

        self.networkFee = (
            bundle.fees.gas.amount,
            bundle.fees.gas.usdAmount,
            false
        )

        if let createAccount = bundle.fees.createAccount {
            self.accountCreationFee = (
                createAccount.amount,
                createAccount.usdAmount,
                false
            )
        } else {
            self.accountCreationFee = nil
        }

        self.wormholeBridgeAndTrxFee = (
            bundle.fees.arbiter.amount,
            bundle.fees.arbiter.usdAmount,
            false
        )
    }
}
