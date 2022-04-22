//
//  ConfirmReceivingBitcoin.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation

enum ConfirmReceivingBitcoin {
    struct Output {
        var isLoading: Bool = true
        var accountStatus: RenBTCAccountStatus?
    }

    enum RenBTCAccountStatus {
        case topUpRequired
        case payingWalletAvailable
    }
}
