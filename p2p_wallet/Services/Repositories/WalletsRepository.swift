//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView_Combine
import Foundation
import Combine
import SolanaSwift

protocol WalletsRepository: BECollectionViewModelType {
    var nativeWallet: Wallet? { get }
    func getWallets() -> [Wallet]
    var statePublisher: AnyPublisher<BEFetcherState, Never> { get }
    var currentState: BEFetcherState { get }
    var dataPublisher: AnyPublisher<[Wallet], Never> { get }
    func getError() -> Error?
    func reload()
    func toggleWalletVisibility(_ wallet: Wallet)
    func removeItem(where predicate: (Wallet) -> Bool) -> Wallet?
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?)
    func toggleIsHiddenWalletShown()
    var isHiddenWalletsShown: CurrentValueSubject<Bool, Never> { get }
    func hiddenWallets() -> [Wallet]
    func refreshUI()

    func batchUpdate(closure: ([Wallet]) -> [Wallet])
}

extension WalletsViewModel: WalletsRepository {
    var statePublisher: AnyPublisher<BEFetcherState, Never> {
        $state.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var currentState: BEFetcherState {
        state
    }
    
    var dataPublisher: AnyPublisher<[Wallet], Never> {
        $data.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    func getWallets() -> [Wallet] {
        data
    }

    func getError() -> Error? {
        error
    }
}
