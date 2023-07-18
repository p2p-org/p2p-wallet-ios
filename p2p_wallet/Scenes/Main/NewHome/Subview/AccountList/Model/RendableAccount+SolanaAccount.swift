import Foundation
import KeyAppBusiness
import BigDecimal

struct RenderableSolanaAccount: RenderableAccount {
    let account: SolanaAccountsService.Account
    
    var id: String {
        account.id
    }
    
    var icon: AccountIcon {
        if
            let logoURI = account.data.token.logoURI,
            let url = URL(string: logoURI)
        {
            return .url(url)
        } else {
            return .random(seed: account.data.token.address)
        }
    }
    
    var wrapped: Bool {
        account.data.token.wrappedBy != nil
    }
    
    var title: String {
        return account.data.token.name
    }
    
    var subtitle: String {
        if let amount = account.data.amount {
            return amount.tokenAmountFormattedString(symbol: account.data.token.symbol)
        }
        return ""
    }
    
    var detail: AccountDetail {
        return .text(
            account
                .amountInFiatDouble
                .fiatAmountFormattedString(customFormattForLessThan1E_2: true)
        )
    }
    
    let extraAction: AccountExtraAction?
    
    let tags: AccountTags
    
    var sortingKey: BigDecimal? {
        return account.amountInFiat?.value
    }
}
