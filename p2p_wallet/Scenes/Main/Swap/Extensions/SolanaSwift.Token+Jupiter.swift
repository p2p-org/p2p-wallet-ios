import SolanaSwift
import Jupiter

extension SolanaSwift.Token {
    init(jupiterToken: Jupiter.Token) {
        self.init(
            _tags: nil,
            chainId: jupiterToken.chainId,
            address: jupiterToken.address,
            symbol: jupiterToken.symbol,
            name: jupiterToken.name,
            decimals: Decimals(jupiterToken.decimals),
            logoURI: jupiterToken.logoURI,
            extensions: .init(coingeckoId: jupiterToken.extensions?.coingeckoId)
        )
    }
}
