//
//  SolanaSDK.Token+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation

extension SolanaSDK.Token {
    var indicatorColor: UIColor {
        // swiftlint:disable swiftgen_assets
        UIColor(named: symbol) ?? .random
        // swiftlint:enable swiftgen_assets
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
