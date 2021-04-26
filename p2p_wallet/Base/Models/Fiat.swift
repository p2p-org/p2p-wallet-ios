//
//  Fiat.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/02/2021.
//

import Foundation

enum Fiat: String, CaseIterable {
    case usd
    case eur
    
    var code: String {
        rawValue.uppercased()
    }
    
    var symbol: String {
        switch self {
        case .usd:
            return "$"
        case .eur:
            return "€"
        }
    }
    
    var name: String {
        switch self {
        case .usd:
            return L10n.unitedStatesDollar
        case .eur:
            return L10n.euro
        }
    }
}
