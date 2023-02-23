import SolanaSwift
import Jupiter

struct SwapToken: Equatable {
    let jupiterToken: Jupiter.Token
    let userWallet: Wallet?

    var address: String { jupiterToken.address }
}

extension SwapToken {
    static let nativeSolana = SwapToken(
        jupiterToken: .init(
            address: SolanaSwift.Token.nativeSolana.address,
            chainId: SolanaSwift.Token.nativeSolana.chainId,
            decimals: Int(SolanaSwift.Token.nativeSolana.decimals),
            name: SolanaSwift.Token.nativeSolana.name,
            symbol: SolanaSwift.Token.nativeSolana.symbol,
            logoURI: SolanaSwift.Token.nativeSolana.logoURI,
            extensions: nil,
            tags: []
        ),
        userWallet: nil)
}
