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
        case scanQrWithSwiper(progress: CGFloat, state: UIGestureRecognizer.State)
        case sendToken(address: String? = nil)
        case closeReserveNameAlert((ClosingBannerType) -> Void)
        case swapToken
        case settings
        case reserveName(owner: String)
        case walletDetail(wallet: Wallet)
        case walletSettings(wallet: Wallet)
    }
}
