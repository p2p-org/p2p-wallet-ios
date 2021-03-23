//
//  WalletsVM+WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import RxSwift

extension WalletsVM: WalletsRepository {
    var wallets: [Wallet] {items}
    var stateObservable: Observable<FetcherState<[Wallet]>> {
        state.asObservable()
    }
}
