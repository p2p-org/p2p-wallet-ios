import SolanaSwift
import Jupiter
import KeyAppKitCore

struct SwapToken: Equatable {
    let token: Token
    let userWallet: SolanaAccount?

    var address: String { token.address }
}

extension SwapToken {
    static let nativeSolana = SwapToken(
        token: .nativeSolana,
        userWallet: nil)
}

extension SwapToken {
    static let preferTokens = ["USDC", "USDT", "SOL", "WBTC", "WETH"]

    var isPopular: Bool {
        Self.preferTokens.contains(token.symbol)
    }
}
