import Foundation
import SolanaSwift
import UIKit

extension TokenMetadata {
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        var imageName = symbol
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "Ü", with: "U")

        // parse liquidity tokens
        let liquidityTokensPrefixes = ["Raydium", "Orca", "Mercurial"]
        for prefix in liquidityTokensPrefixes {
            if name.contains("\(prefix) "), imageName.contains("-") {
                imageName = "\(prefix)-" + imageName
            }
        }
        return UIImage(named: imageName)
        // swiftlint:enable swiftgen_assets
    }
}

extension TokenMetadata {
    // MARK: - Common tokens

    static var srm: TokenMetadata {
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

    // MARK: - Common grouped tokens

    static var moonpaySellSupportedTokens: [TokenMetadata] = [
        .nativeSolana,
    ]
}
