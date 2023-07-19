//
//  Fiat.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/02/2021.
//

import Foundation

enum Fiat: String, CaseIterable, Hashable, Equatable {
    case usd
    case eur
    case cny
    case vnd
    case rub
    case gbp

    var code: String {
        rawValue.uppercased()
    }

    var symbol: String {
        switch self {
        case .usd:
            return "$"
        case .eur:
            return "€"
        case .cny:
            return "¥"
        case .vnd:
            return "₫"
        case .rub:
            return "₽"
        case .gbp:
            return "£"
        }
    }
}
