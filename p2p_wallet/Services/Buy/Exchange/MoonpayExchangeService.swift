//
// Created by Giang Long Tran on 21.02.2022.
//

import Foundation
import Moonpay

protocol MoonpayCodeMapping {
    var moonpayCode: String { get }
}

extension Buy.CryptoCurrency: MoonpayCodeMapping {
    var moonpayCode: String {
        switch self {
        case .eth:
            return "eth"
        case .sol:
            return "sol"
        case .usdc:
            return "usdc_sol"
        }
    }
}

extension Buy.FiatCurrency: MoonpayCodeMapping {
    var moonpayCode: String {
        switch self {
        case .usd:
            return "usd"
        case .eur:
            return "eur"
        case .cny:
            return "cny"
        case .vnd:
            return "vnd"
        case .rub:
            return "rub"
        case .gbp:
            return "gbp"
        }
    }
}
