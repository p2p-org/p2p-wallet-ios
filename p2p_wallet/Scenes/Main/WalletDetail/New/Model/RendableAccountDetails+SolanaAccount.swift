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
            return [.cashOut, .buy, .swap(account), .receive(.solanaAccount(account)), .send]
        } else if account.token.symbol == "USDC" {
            return [.buy, .receive(.solanaAccount(account)), .swap(account), .send]
        } else {
            return [.receive(.solanaAccount(account)), .swap(account), .send]
        }
    }

    var onAction: (RendableAccountDetailsAction) -> Void
}
