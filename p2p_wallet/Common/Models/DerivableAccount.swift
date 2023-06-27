//
//  DerivableAccount.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation
import SolanaSwift

struct DerivableAccount: Hashable, Identifiable {
    let derivablePath: DerivablePath
    let info: KeyPair
    var amount: Double?
    var price: Double?

    // additional
    var isBlured: Bool?

    var id: String {
        info.publicKey.base58EncodedString
    }
}
