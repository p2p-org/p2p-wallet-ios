//
//  ConfirmReceivingBitcoin.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import SolanaSwift

enum ConfirmReceivingBitcoin {
    enum NavigatableScene {
        case chooseWallet(selectedWallet: Wallet?, payableWallets: [Wallet])
    }

    enum RenBTCAccountStatus {
        case topUpRequired
        case payingWalletAvailable
    }
}
