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
        var color = UIColor(named: symbol) ?? SolanaSDK.Token.cachedIndicatorColors[symbol]
        // swiftlint:enable swiftgen_assets
        if color == nil {
            color = .random
            SolanaSDK.Token.cachedIndicatorColors[symbol] = color
        }
        return color!
    }
    
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        UIImage(named: symbol)
        // swiftlint:enable swiftgen_assets
    }
    
    var description: String {
        if symbol == "SOL" {
            return "Solana"
        }
        if let wrappedBy = wrappedBy {
            return L10n.wrappedBy(symbol, wrappedBy.rawValue)
        }
        return name
    }
}
