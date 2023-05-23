import UIKit

enum WalletActionType {
    case receive
    case topUp
    case buy
    case send
    case swap
    case cashOut

    var text: String {
        switch self {
        case .topUp:
            return L10n.topUp
        case .receive:
            return L10n.receive
        case .buy:
            return L10n.buy.uppercaseFirst
        case .send:
            return L10n.send
        case .swap:
            return L10n.swap
        case .cashOut:
            return L10n.cashOut
        }
    }

    var icon: UIImage {
        switch self {
        case .topUp:
            return .homeBuy
        case .receive:
            return .homeReceive
        case .buy:
            return .homeBuy
        case .send:
            return .homeSend
        case .swap:
            return .homeSwap
        case .cashOut:
            return .cashOut
        }
    }
}
