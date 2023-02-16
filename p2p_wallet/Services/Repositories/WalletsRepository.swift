//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView
import Foundation
import RxCocoa
import RxSwift
import RxCombine
import SolanaSwift
import Combine

protocol WalletsRepository: BEListViewModelType {
    var nativeWallet: Wallet? { get }
    func getWallets() -> [Wallet]
    var stateObservable: Observable<BEFetcherState> { get }
    var dataDidChange: Observable<Void> { get }
    var dataObservable: Observable<[Wallet]?> { get }
    func getError() -> Error?
    func reload()
    func toggleWalletVisibility(_ wallet: Wallet)
    func removeItem(where predicate: (Wallet) -> Bool) -> Wallet?
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?)
    func toggleIsHiddenWalletShown()
    var isHiddenWalletsShown: BehaviorRelay<Bool> { get }
    func hiddenWallets() -> [Wallet]
    func refreshUI()

    func batchUpdate(closure: ([Wallet]) -> [Wallet])
    
    // Combine migration
    var dataPublisher: AnyPublisher<[Wallet], Never> { get }
}

extension WalletsViewModel: WalletsRepository {
    func getWallets() -> [Wallet] {
        data
    }

    func getError() -> Error? {
        error
    }

    func batchUpdate(closure: ([Wallet]) -> [Wallet]) {
        let wallets = closure(getWallets())
        overrideData(by: wallets)
    }
    
    var dataPublisher: AnyPublisher<[Wallet], Never> {
        dataObservable
            .publisher
            .compactMap { $0 }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
}
