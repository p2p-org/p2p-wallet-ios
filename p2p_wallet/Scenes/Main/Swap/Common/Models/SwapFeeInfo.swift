import Foundation

struct SwapFeeInfo: Equatable {
    let amount: Double
    let tokenSymbol: String?
    let tokenName: String?
    let amountInFiat: Double?
    let pct: Double?
    let canBePaidByKeyApp: Bool
    
    var amountDescription: String? {
        amount == 0 && canBePaidByKeyApp ? L10n.paidByKeyApp: amount.tokenAmountFormattedString(symbol: tokenSymbol ?? "")
    }
    var shouldHighlightAmountDescription: Bool {
        amount == 0 && canBePaidByKeyApp
    }
    
    var amountInFiatDescription: String? {
        amount == 0 && canBePaidByKeyApp ? L10n.free: "≈ " + (amountInFiat?.fiatAmountFormattedString() ?? "")
    }
}
