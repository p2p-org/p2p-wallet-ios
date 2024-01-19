import Foundation
import KeyAppKitCore

struct RendableNewSolanaAccountDetails: RendableAccountDetails {
    let account: SolanaAccount

    let isSwapAvailable: Bool

    var title: String {
        account.token.name
    }

    var amountInToken: String {
        account.amount?.tokenAmountFormattedString(symbol: account.token.symbol) ?? ""
    }

    var amountInFiat: String {
        account.amountInFiatDouble.fiatAmountFormattedString()
    }

    var actions: [RendableAccountDetailsAction] {
        if account.token.isNative {
            return [.cashOut, .buy, .receive(.solanaAccount(account)), .send, .swap(account)]
        } else if account.token.symbol == "USDC" {
            return [.buy, .receive(.solanaAccount(account)), .send, .swap(account)]
        } else {
            return [.receive(.solanaAccount(account)), .send, .swap(account)]
        }
    }

    var onAction: (RendableAccountDetailsAction) -> Void
}
