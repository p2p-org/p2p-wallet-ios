import Foundation

struct SwapFeeInfo: Equatable {
    let amount: Double
    let token: String?
    let amountInFiat: Double?
    let canBePaidByKeyApp: Bool
    
    var amountDescription: String? {
        amount == 0 && canBePaidByKeyApp ? L10n.paidByKeyApp: amount.tokenAmountFormattedString(symbol: token ?? "")
    }
    var shouldHighlightAmountDescription: Bool {
        amount == 0 && canBePaidByKeyApp
    }
    
    var amountInFiatDescription: String? {
        amount == 0 && canBePaidByKeyApp ? L10n.free: "≈ " + (amountInFiat?.fiatAmountFormattedString() ?? "")
    }
}
