//
//  DerivableAccount.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation

struct DerivableAccount: Hashable {
    let info: SolanaSDK.Account
    var amount: Double?
    var price: Double?

    // additional
    var isBlured: Bool?
}
