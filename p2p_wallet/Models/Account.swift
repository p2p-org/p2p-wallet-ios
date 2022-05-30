//
//  Account.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation
import SolanaSwift

struct Account: Codable, Hashable {
    let name: String?
    let phrase: String
    let derivablePath: DerivablePath
}
