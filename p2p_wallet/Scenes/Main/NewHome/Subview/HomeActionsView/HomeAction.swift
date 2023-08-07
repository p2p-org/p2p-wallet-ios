import KeyAppUI
import SwiftUI

enum HomeAction {
    case addMoney
    case withdraw

    var text: String {
        switch self {
        case .addMoney:
            return L10n.addMoney
        case .withdraw:
            return L10n.withdraw
        }
    }

    var image: UIImage {
        switch self {
        case .addMoney:
            return .addMoneyButton
        case .withdraw:
            return .withdrawButton
        }
    }
}
