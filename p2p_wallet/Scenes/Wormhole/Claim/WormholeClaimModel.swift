//
//  WormholeModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore

protocol WormholeClaimModel {
    var icon: URL? { get }
    var title: String { get }
    var subtitle: String { get }
}

struct WormholeClaimMockModel: WormholeClaimModel {
    var icon: URL?

    var title: String

    var subtitle: String
}

struct WormholeClaimEthereumModel: WormholeClaimModel {
    let account: EthereumAccountsService.Account

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

        guard let formattedValue = CurrencyFormatter().string(for: currencyAmount) else {
            return ""
        }
        return "~ \(formattedValue)"
    }
}
