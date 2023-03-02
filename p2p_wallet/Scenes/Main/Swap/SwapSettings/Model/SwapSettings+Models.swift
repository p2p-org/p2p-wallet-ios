//
import Foundation

struct SwapSettingsRouteInfo: Identifiable {
    init(id: String = UUID().uuidString, name: String, description: String, tokensChain: String) {
        self.id = id
        self.name = name
        self.description = description
        self.tokensChain = tokensChain
    }
    
    let id: String
    let name: String
    let description: String
    let tokensChain: String
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
