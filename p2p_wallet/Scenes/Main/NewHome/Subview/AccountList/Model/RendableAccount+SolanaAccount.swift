import BigDecimal
import Foundation
import KeyAppBusiness
import KeyAppKitCore

struct RenderableSolanaAccount: RenderableAccount {
    let account: SolanaAccountsService.Account

    var id: String {
        account.id
    }

    var icon: AccountIcon {
        if
            let logoURI = account.token.logoURI,
            let url = URL(string: logoURI)
        {
            return .url(url)
        } else {
            return .random(seed: account.token.mintAddress)
        }
    }

    var wrapped: Bool {
        account.token.wrapped
    }

    var title: String {
        account.token.name
    }

    var subtitle: String {
        if let amount = account.amount {
            return amount.tokenAmountFormattedString(symbol: account.token.symbol, roundingMode: .down)
        }
        return ""
    }

    var detail: AccountDetail {
        if account.price != nil, let amountInFiat = account.amountInFiat {
            return .text(
                CurrencyFormatter().string(amount: amountInFiat)
            )
        } else {
            return .text("")
        }
    }

    let extraAction: AccountExtraAction?

    let tags: AccountTags

    var sortingKey: BigDecimal? {
        account.amountInFiat?.value
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.account == rhs.account
    }
}
