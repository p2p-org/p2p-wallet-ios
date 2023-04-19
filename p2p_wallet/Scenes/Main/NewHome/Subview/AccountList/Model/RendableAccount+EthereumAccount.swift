import Foundation
import KeyAppBusiness
import KeyAppKitCore

struct RenderableEthereumAccount: RendableAccount {
    let account: EthereumAccount

    let status: Status

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
        CryptoFormatterFactory.formatter(with: account.representedBalance.token, style: .short)
            .string(for: account.representedBalance)
            ?? "0 \(account.token.symbol)"
    }

    var detail: AccountDetail {
        switch status {
        case .readyToClaim:
            return .button(label: L10n.claim, enabled: true)
        case .isClamming:
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
            tags.insert(.ignore)
        }

        return tags
    }
}

extension RenderableEthereumAccount {
    enum Status: Equatable {
        case readyToClaim
        case isClamming
        case balanceToLow
    }
}
