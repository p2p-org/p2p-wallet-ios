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
}
