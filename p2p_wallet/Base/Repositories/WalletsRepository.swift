//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import RxSwift

protocol WalletsRepository {
    func getWallets() -> [Wallet]
    func stateObservable() -> Observable<BEFetcherState>
    func getError() -> Error?
    func reload()
}
