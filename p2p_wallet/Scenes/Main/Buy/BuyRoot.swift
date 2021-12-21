//
//  BuyRoot.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.12.21.
//

import Foundation
import RxCocoa

enum BuyRoot {
    enum NavigatableScene {
        case solanaBuyToken
        case buyToken(crypto: BuyProviders.Crypto, amount: Double)
        case back
        case none
    }
}
