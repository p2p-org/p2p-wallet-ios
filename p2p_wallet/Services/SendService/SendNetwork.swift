import Foundation

enum SendNetwork: String {
    case solana, bitcoin
    var icon: UIImage {
        switch self {
        case .solana:
            return .squircleSolanaIcon
        case .bitcoin:
            return .squircleBitcoinIcon
        }
    }
}
