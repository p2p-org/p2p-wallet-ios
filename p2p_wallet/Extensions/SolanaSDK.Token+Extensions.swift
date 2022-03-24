//
//  SolanaSDK.Token+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation

extension SolanaSDK.Token {
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
