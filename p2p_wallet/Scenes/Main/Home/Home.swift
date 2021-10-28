//
//  Home.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Foundation
import RxCocoa

struct Home {
    enum NavigatableScene {
        case buyToken
        case receiveToken
        case scanQr
        case sendToken(address: String? = nil)
        case swapToken
        case allProducts
        case settings
        case reserveName(owner: String)
        case walletDetail(wallet: Wallet)
        case walletSettings(wallet: Wallet)
    }
}
