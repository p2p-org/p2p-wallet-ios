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
    let account: EthereumAccountsService.Account
    
    var id: String {
        switch account.token.contractType {
        case let .native(address):
            return address.hex(eip55: false)
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
        CryptoFormatter().string(for: account.representedBalance)
            ?? "0 \(account.token.symbol)"
    }
    
    var detail: AccountDetail {
        return .button(label: L10n.claim, action: onTap)
    }
    
    var extraAction: AccountExtraAction? {
        nil
    }
    
    var tags: AccountTags {
        []
    }
    
    var onTap: (() -> Void)?
}
