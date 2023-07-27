import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift
import Wormhole
import UIKit
import BigDecimal

struct RenderableEthereumAccount: RenderableAccount, Equatable {
    let account: EthereumAccount
    let status: Status
    let userAction: WormholeClaimUserAction?

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
        switch status {
        case .readyToClaim, .isClaiming:
            return L10n.incomingTransfer
        default:
            return account.token.name
        }
    }

    var subtitle: String {
        if let userAction {
            return CryptoFormatterFactory.formatter(with: userAction.amountInCrypto.token, style: .short)
                .string(amount: userAction.amountInCrypto)
        } else {
            return CryptoFormatterFactory.formatter(with: account.representedBalance.token, style: .short)
                .string(amount: account.representedBalance)
        }
    }

    var detail: AccountDetail {
        switch status {
        case .readyToClaim:
            return .button(label: L10n.claim, enabled: true)
        case .isClaiming:
            return .button(label: L10n.claiming, enabled: false)
        case .balanceToLow:
            if let balanceInFiat = account.balanceInFiat {
                return .text(CurrencyFormatter().string(amount: balanceInFiat))
            } else {
                return .text("")
            }
        }
    }

    var extraAction: AccountExtraAction? {
        nil
    }

    var tags: AccountTags {
        var tags: AccountTags = []

        if status == .balanceToLow {
            if account.balance == 0 {
                tags.insert(.hidden)
            } else {
                tags.insert(.ignore)
            }
        }

        return tags
    }
    
    var sortingKey: BigDecimal? {
        return account.balanceInFiat?.value
    }
}

extension RenderableEthereumAccount {
    enum Status: Hashable {
        case readyToClaim
        case isClaiming
        case balanceToLow
    }
}
