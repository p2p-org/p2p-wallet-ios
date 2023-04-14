import Foundation
import KeyAppBusiness
import KeyAppKitCore

struct RenderableEthereumAccount: RendableAccount {
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
        CryptoFormatterFactory.formatter(with: account.representedBalance.token, style: .short)
            .string(for: account.representedBalance)
            ?? "0 \(account.token.symbol)"
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
