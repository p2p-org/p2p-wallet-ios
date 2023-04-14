//
//  RendableAccount+EthereumAccount.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore

struct RendableEthereumAccount: RendableAccount {
    let account: EthereumAccount

    var id: String {
        switch account.token.contractType {
        case .native:
            return account.address
        case let .erc20(contract):
            return contract.hex(eip55: false)
        }
    }

    var icon: AccountIcon {
        if let url = account.token.logo {
            return .url(url)
        } else {
            return .image(.imageOutlineIcon)
        }
    }

    var wrapped: Bool {
        false
    }

    var title: String {
        account.token.name
    }

    var subtitle: String {
        CryptoFormatter(rules: [.nativeEthereumMaxDigit])
            .string(amount: account.representedBalance)
    }

    var detail: AccountDetail {
        if let onClaim {
            return .button(label: L10n.claim, action: onClaim)
        } else if isClaiming {
            return .button(label: L10n.claiming, action: nil)
        } else if let balanceInFiat = account.balanceInFiat {
            return .text(CurrencyFormatter().string(amount: balanceInFiat))
        } else {
            return .text("")
        }
    }

    var extraAction: AccountExtraAction? {
        nil
    }

    var tags: AccountTags {
        []
    }

    let isClaiming: Bool

    let onTap: (() -> Void)?

    let onClaim: (() -> Void)?
}
