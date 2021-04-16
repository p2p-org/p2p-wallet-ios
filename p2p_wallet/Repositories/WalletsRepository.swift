//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import RxSwift
import RxCocoa
import BECollectionView

protocol WalletsRepository: BEListViewModelType {
    var solWallet: Wallet? {get}
    func getWallets() -> [Wallet]
    var stateObservable: Observable<BEFetcherState> {get}
    var dataDidChange: Observable<Void> {get}
    var dataObservable: Observable<[Wallet]?> {get}
    func getError() -> Error?
    func reload()
    func insert(_ item: Wallet, where predicate: (Wallet) -> Bool, shouldUpdate: Bool) -> Bool
    func updateWallet(_ wallet: Wallet, withName name: String)
    func toggleWalletVisibility(_ wallet: Wallet)
    func removeItem(where predicate: (Wallet) -> Bool) -> Wallet?
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?)
    func toggleIsHiddenWalletShown()
    var isHiddenWalletsShown: BehaviorRelay<Bool> {get}
    func hiddenWallets() -> [Wallet]
    func refreshUI()
}

extension WalletsViewModel: WalletsRepository {
    func getWallets() -> [Wallet] {
        data
    }
    
    func getError() -> Error? {
        error
    }
}
