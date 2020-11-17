//
//  NSRegularExpression+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/11/2020.
//

import Foundation

extension NSRegularExpression {
    var publicKey: String { #"^[1-9A-HJ-NP-Za-km-z]{44}$"# }
}
