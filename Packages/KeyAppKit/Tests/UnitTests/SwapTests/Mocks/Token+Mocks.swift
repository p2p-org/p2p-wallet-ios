import Foundation
import SolanaSwift

extension Token {
    static var srm: Token {
        .init(
            _tags: nil,
            chainId: 101,
            address: "SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt",
            symbol: "SRM",
            name: "Serum",
            decimals: 6,
            logoURI: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt/logo.png",
            extensions: .init(
                website: "https://projectserum.com/",
                serumV3Usdt: "AtNnsY1AyRERWJ8xCskfz38YdvruWVJQUVXgScC1iPb",
                serumV3Usdc: "ByRys5tuUWDgL73G8JBAEfkdFf8JWBzPBDHsBVQ5vbQA",
                coingeckoId: "serum"
            )
        )
    }
}
