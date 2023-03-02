//
import Foundation

protocol SwapSettingsRouteInfo {
    var name: String { get}
    var description: String { get}
    var tokens: String { get}
}

struct SwapSettingsTokenAmountInfo {
    let amount: Double
    let token: String?
    
    var amountDescription: String? {
        amount.tokenAmountFormattedString(symbol: token ?? "")
    }
}

struct SwapSettingsFeeInfo {
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
        amount == 0 ? L10n.free: "≈ " + (amountInFiat?.fiatAmountFormattedString() ?? "")
    }
}
