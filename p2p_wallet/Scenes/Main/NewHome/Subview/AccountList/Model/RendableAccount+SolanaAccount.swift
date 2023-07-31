import BigDecimal
import Foundation
import KeyAppBusiness

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
        if account.price != nil {
            return .text(
                account
                    .amountInFiatDouble
                    .fiatAmountFormattedString(customFormattForLessThan1E_2: true)
            )
        } else {
            return .text("")
        }
    }

    let extraAction: AccountExtraAction?

    let tags: AccountTags

    var isLoading: Bool { false }

    var sortingKey: BigDecimal? {
        account.amountInFiat?.value
    }
}
