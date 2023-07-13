import Foundation

enum WalletActionType {
    case receive
    case buy
    case send
    case swap
    case cashOut

    var text: String {
        switch self {
        case .receive:
            return L10n.receive
        case .buy:
            return L10n.buy.uppercaseFirst
        case .send:
            return L10n.send
        case .swap:
            return L10n.swap
        case .cashOut:
            return "Cash out"
        }
    }

    var icon: ImageResource {
        switch self {
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
