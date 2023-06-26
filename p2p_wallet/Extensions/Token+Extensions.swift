//
//  Token+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation
import SolanaSwift
import SolanaToken

extension Token {
    var maxAmount: Double {
        (Double(Lamports.max) / pow(10, Double(decimals)))
            .rounded(decimals: 0, roundingMode: .down)
    }
}

extension Token {
    // MARK: - Common grouped tokens

    static var moonpaySellSupportedTokens: [Token] = [
        .nativeSolana,
    ]
}
