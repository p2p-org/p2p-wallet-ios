import SolanaSwift
import Jupiter

struct SwapToken: Equatable {
    let token: Token
    let userWallet: Wallet?

    var address: String { token.address }
}

extension SwapToken {
    static let nativeSolana = SwapToken(
        token: .nativeSolana,
        userWallet: nil)
}
