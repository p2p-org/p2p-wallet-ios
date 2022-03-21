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

    var name: String {
        switch self {
        case .usd:
            return L10n.unitedStatesDollar
        case .eur:
            return L10n.euro
        case .cny:
            return L10n.chineseYuan
        case .vnd:
            return L10n.vietnameseDong
        case .rub:
            return L10n.russianRuble
        case .gbp:
            return L10n.britishPoundSterling
        }
    }
}
