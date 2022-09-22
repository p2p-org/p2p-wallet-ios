//
//  BuyRoot.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.12.21.
//

import Foundation

enum BuyRoot {
    enum NavigatableScene {
        case buyToken(crypto: Buy.CryptoCurrency, amount: Double)
        case back
        case none
    }
}
