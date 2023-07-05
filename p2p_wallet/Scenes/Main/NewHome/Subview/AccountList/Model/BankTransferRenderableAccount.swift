import BankTransfer
import Foundation
import KeyAppKitCore

struct BankTransferRenderableAccount: RenderableAccount {
    let accountId: String
    let token: EthereumToken
    let amount: CryptoAmount
    var status: RenderableEthereumAccount.Status

    var id: String {
        accountId
    }

    var icon: AccountIcon {
        if let url = token.logo {
            return .url(url)
        } else {
            return .image(.imageOutlineIcon)
        }
    }

    var wrapped: Bool {
        false
    }

    var title: String {
        token.name
    }

    var subtitle: String {
        CryptoFormatterFactory.formatter(
            with: amount.token,
            style: .short
        )
            .string(amount: amount)
    }

    var detail: AccountDetail {
        switch status {
        case .readyToClaim:
            return .button(label: L10n.claim, enabled: true)
        case .isClamming:
            return .button(label: L10n.claim, enabled: false)
        case .balanceToLow:
            return .text("")
        }
    }

    var extraAction: AccountExtraAction? {
        nil
    }

    var tags: AccountTags {
        var tags: AccountTags = []

        if status == .balanceToLow {
            if amount.amount == 0 {
                tags.insert(.hidden)
            } else {
                tags.insert(.ignore)
            }
        }
        return tags
    }

    var isLoading: Bool {
        switch status {
        case .isClamming:
            return true
        default:
            return false
        }
    }
}
