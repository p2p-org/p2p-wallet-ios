import Jupiter
import KeyAppKitCore
import SolanaSwift

struct SwapToken: Equatable {
    let token: TokenMetadata
    let userWallet: SolanaAccount?

    var address: String { token.address }
}

extension SwapToken {
    static let nativeSolana = SwapToken(
        token: .nativeSolana,
        userWallet: nil
    )
}

extension SwapToken {
    static let preferTokens = ["USDC", "USDT", "SOL", "WBTC", "WETH"]

    var isPopular: Bool {
        Self.preferTokens.contains(token.symbol)
    }
}
