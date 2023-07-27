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

    var image: ImageResource {
        switch self {
        case .addMoney:
            return .addMoneyButton
        case .withdraw:
            return .withdrawButton
        }
    }
}
