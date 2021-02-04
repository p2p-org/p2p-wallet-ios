//
//  Fiat.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/02/2021.
//

import Foundation

enum Fiat: String {
    case usd
    
    var code: String {
        rawValue.uppercased()
    }
}
