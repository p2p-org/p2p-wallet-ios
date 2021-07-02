//
//  SolanaSDK.Token+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation

extension SolanaSDK.Token {
    private static var cachedIndicatorColors = [String: UIColor]()
    
    var indicatorColor: UIColor {
        // swiftlint:disable swiftgen_assets
        var color = UIColor(named: symbol + "-BGCOLOR") ?? SolanaSDK.Token.cachedIndicatorColors[symbol]
        // swiftlint:enable swiftgen_assets
        if color == nil {
            color = .random
            // get unique colors
            while SolanaSDK.Token.cachedIndicatorColors.values
                    .contains(where: {$0 == color})
            {
                color = .random
            }
            // save
            SolanaSDK.Token.cachedIndicatorColors[symbol] = color
        }
        return color!
    }
    
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        var imageName = symbol
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "Ü", with: "U")
        
        // parse liquidity tokens
        if name.contains("Raydium ") && symbol.contains("-") {
            imageName = "Raydium-" + imageName
        }
        if name.contains("Orca ") && symbol.contains("/") {
            imageName = "Orca-" + imageName
        }
        return UIImage(named: imageName)
        // swiftlint:enable swiftgen_assets
    }
    
//    var description: String {
//        if symbol == "SOL" {
//            return "Solana"
//        }
//        if let wrappedBy = wrappedBy {
//            return L10n.wrappedBy(symbol, wrappedBy.rawValue.uppercaseFirst)
//        }
//        return name
//    }
}
