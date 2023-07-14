import BankTransfer
import Foundation
import KeyAppKitCore
import BigInt

struct BankTransferRenderableAccount: RenderableAccount {
    let accountId: String
    let token: EthereumToken
    let visibleAmount: Int
    let rawAmount: Int
    var status: RenderableEthereumAccount.Status
    private var amount: CryptoAmount {
        .init(amount: BigUInt(visibleAmount.toCent()), token: token)
    }

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
        case .isClaimming:
            return .button(label: L10n.claim, enabled: true)
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
        case .isClaimming:
            return true
        default:
            return false
        }
    }
}

private extension Int {
    func toCent() -> Double {
        Double(self * 10_000)
    }
}
