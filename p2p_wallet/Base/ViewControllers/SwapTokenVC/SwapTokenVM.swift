//
//  SwapTokenVM.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

class SwapTokenVM {
    var pools: Single<[SolanaSDK.Pool]> {
        SolanaSDK.shared.getSwapPools()
    }
    let walletsVM = WalletsVM.ofCurrentUser
}
