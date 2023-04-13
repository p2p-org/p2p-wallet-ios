import Foundation
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift
import Wormhole

struct SOLRenderableEthereumAccount: RenderableAccount, ClaimableRenderableAccount {
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
        guard let url = URL(string: Token.nativeSolana.logoURI ?? "") else {
            return .image(.imageOutlineIcon)
        }
        return .url(url)
    }

    var wrapped: Bool {
        false
    }

    var title: String {
        Token.nativeSolana.name
    }

    var subtitle: String {
        CryptoFormatter().string(for: account.representedBalance)
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
