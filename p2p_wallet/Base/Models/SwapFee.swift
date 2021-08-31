//
//  SwapFee.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/08/2021.
//

import Foundation

enum FeeType {
    case `default`
    case liquidityProvider
}
struct SwapFee {
    let lamports: SolanaSDK.Lamports
    let token: SolanaSDK.Token
    var toString: (() -> String?)?
}
