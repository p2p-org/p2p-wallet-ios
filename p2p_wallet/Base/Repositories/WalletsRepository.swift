//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import RxSwift
import BECollectionView

protocol WalletsRepository {
    var solWallet: Wallet? {get}
    func getWallets() -> [Wallet]
    func stateObservable() -> Observable<BEFetcherState>
    var dataDidChange: Observable<Void> {get}
    func getError() -> Error?
    func reload()
    func insert(_ item: Wallet, where predicate: (Wallet) -> Bool, shouldUpdate: Bool)
}
