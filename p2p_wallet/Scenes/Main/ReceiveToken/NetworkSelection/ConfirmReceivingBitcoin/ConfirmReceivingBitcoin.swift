//
//  ConfirmReceivingBitcoin.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation

enum ConfirmReceivingBitcoin {
    struct Output {
        let isLoading: Bool
        let accountStatus: RenBTCAccountStatus?

        static var initializing: Self {
            .init(isLoading: false, accountStatus: nil)
        }
    }

    enum RenBTCAccountStatus {
        case topUpRequired
        case payingWalletAvailable
    }
}
