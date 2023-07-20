import SwiftUI
import KeyAppUI

enum ActionsViewActionType: CaseIterable {
    case bankTransfer
    case bankCard
    case crypto
    
    var title: String {
        switch self {
        case .bankTransfer:
            return L10n.bankTransfer
        case .bankCard:
            return L10n.bankCard
        case .crypto:
            return L10n.crypto
        }
    }
    
    var subtitle: String {
        switch self {
        case .bankTransfer:
            return "1% fee"
        case .bankCard:
            return "4.5% fees"
        case .crypto:
            return "0% fees"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .bankTransfer:
            return .addMoneyBankTransfer
        case .bankCard:
            return .addMoneyBankCard
        case .crypto:
            return .addMoneyCrypto
        }
    }
}
