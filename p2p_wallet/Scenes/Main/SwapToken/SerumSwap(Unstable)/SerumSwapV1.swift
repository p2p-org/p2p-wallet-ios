//
//  SwapToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxCocoa
import RxSwift

struct SerumSwapV1 {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet
        case settings
        case chooseSlippage
        case swapFees
        case processTransaction
    }
}

protocol SwapTokenScenesFactory {
    func makeChooseWalletViewController(
        title: String?,
        customFilter: ((Wallet) -> Bool)?,
        showOtherWallets: Bool,
        selectedWallet: Wallet?,
        handler: WalletDidSelectHandler
    ) -> ChooseWallet.ViewController
}
