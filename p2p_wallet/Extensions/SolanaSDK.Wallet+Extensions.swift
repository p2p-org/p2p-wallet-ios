//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2021.
//

import Foundation
import SolanaPricesAPIs
import SolanaSwift

extension Wallet {
    var name: String {
        token.symbol
    }

    var mintAddress: String {
        token.address
    }
}
