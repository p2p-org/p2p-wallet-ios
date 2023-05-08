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
            return .random(seed: account.token.address)
        }
    }
    
    var wrapped: Bool {
        account.token.wrappedBy != nil
    }
    
    var title: String {
        return account.token.name
    }
    
    var subtitle: String {
        if let amount = account.amount {
            return amount.tokenAmountFormattedString(symbol: account.token.symbol)
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
}
