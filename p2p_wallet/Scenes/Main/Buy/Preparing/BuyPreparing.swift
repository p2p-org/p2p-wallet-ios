//
//  Preparing.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation

enum SolanaBuyToken {
    enum NavigatableScene {
        case back
        case buy
    }
    
    enum State {
        case result(quote: Moonpay.BuyQuote)
        case requiredMinimalAmount
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
