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
    // MARK: - Common grouped tokens

    static var moonpaySellSupportedTokens: [TokenMetadata] = [
        .nativeSolana,
    ]
}
