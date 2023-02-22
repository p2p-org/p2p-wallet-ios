//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView_Combine
import Foundation
import SolanaSwift
import Combine

protocol WalletsRepository: BECollectionViewModelType {
    var nativeWallet: Wallet? { get }
    func getWallets() -> [Wallet]
    var statePublisher: AnyPublisher<BEFetcherState, Never> { get }
    var dataDidChange: AnyPublisher<Void, Never> { get }
    var dataPublisher: AnyPublisher<[Wallet], Never> { get }
    func getError() -> Error?
    func reload()
    func toggleWalletVisibility(_ wallet: Wallet)
    func removeItem(where predicate: (Wallet) -> Bool) -> Wallet?
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?)
    func toggleIsHiddenWalletShown()
    var isHiddenWalletsShown: Bool { get }
    func hiddenWallets() -> [Wallet]
    func refreshUI()

    func batchUpdate(closure: ([Wallet]) -> [Wallet])
}

extension WalletsViewModel: WalletsRepository {
    
    var statePublisher: AnyPublisher<BEFetcherState, Never> {
        $state.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    var dataPublisher: AnyPublisher<[Wallet], Never> {
        $data.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    var currentState: BEFetcherState {
        state
    }
    
    func getWallets() -> [Wallet] {
        data
    }

    func getError() -> Error? {
        error
    }
}
