import SwiftUI

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
            return L10n._0Fees
        case .bankCard:
            return L10n._45Fees
        case .crypto:
            return L10n._0Fees
        }
    }

    var icon: ImageResource {
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
