//
//  WormholeModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

protocol WormholeClaimModel {
    var icon: URL? { get }

    var title: String { get }

    var subtitle: String { get }

    var claimButtonTitle: String { get }

    var claimButtonEnable: Bool { get }

    var fees: String { get }

    var feesButtonEnable: Bool { get }
}

struct WormholeClaimMockModel: WormholeClaimModel {
    var icon: URL?

    var title: String

    var subtitle: String

    var claimButtonTitle: String

    var claimButtonEnable: Bool

    var fees: String

    var feesButtonEnable: Bool
}

struct WormholeClaimEthereumModel: WormholeClaimModel {
    let account: EthereumAccount
    let bundle: AsyncValueState<WormholeBundle?>

    var icon: URL? {
        account.token.logo
    }

    var title: String {
        CryptoFormatter().string(for: account.representedBalance)
            ?? "0 \(account.token.symbol)"
    }

    var subtitle: String {
        guard let currencyAmount = account.balanceInFiat else {
            return ""
        }

        let formattedValue = CurrencyFormatter().string(amount: currencyAmount)
        return "~ \(formattedValue)"
    }

    var claimButtonTitle: String {
        let resultAmount = bundle.value?.resultAmount

        if let resultAmount = resultAmount {
            let cryptoFormatter = CryptoFormatter()

            let cryptoAmount = CryptoAmount(
                bigUIntString: resultAmount.amount,
                token: account.token
            )

            return L10n.claim(cryptoFormatter.string(amount: cryptoAmount))
        } else {
            if bundle.error != nil {
                return L10n.tryAgain
            } else {
                return L10n.loading
            }
        }
    }

    var claimButtonEnable: Bool {
        switch bundle.status {
        case .fetching, .initializing:
            return false
        case .ready:
            return true
        }
    }

    var fees: String {
        let fees = bundle.value?.fees

        guard let fees else {
            return L10n.isUnavailable(L10n.value)
        }

        return CurrencyFormatter().string(amount: fees.totalInFiat)
    }

    var feesButtonEnable: Bool {
        bundle.value?.fees != nil
    }
}
