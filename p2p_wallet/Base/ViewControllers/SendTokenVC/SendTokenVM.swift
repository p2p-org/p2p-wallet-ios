//
//  SendTokenVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/02/2021.
//

import Foundation
import RxCocoa

struct _SendTokenVM {
    let destinationAddress = BehaviorRelay<String?>(value: nil)
    let selectedWalletPubkey = BehaviorRelay<String?>(value: nil)
}
