//
//  SolanaBuyToken.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation

enum SolanaBuyToken {
    enum State {
        case result(quote: Moonpay.BuyQuote)
        case error(_ description: String)
        case none
        
        func asResult() -> Moonpay.BuyQuote? {
            switch self {
            case .result(let quote): return quote
            default: return nil
            }
        }
    }
}
