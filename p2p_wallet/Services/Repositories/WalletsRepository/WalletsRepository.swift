//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import Combine
import SolanaSwift

protocol WalletsRepository {
    var nativeWallet: Wallet? { get }
    func getWallets() -> [Wallet]
    var statePublisher: AnyPublisher<LoadingState, Never> { get }
    var currentState: LoadingState { get }
    var dataPublisher: AnyPublisher<[Wallet], Never> { get }
    func getError() -> Error?
    func reload()
    func toggleWalletVisibility(_ wallet: Wallet)
    func removeItem(where predicate: (Wallet) -> Bool) -> Wallet?
    func toggleIsHiddenWalletShown()
    var isHiddenWalletsShown: Bool { get }
    func hiddenWallets() -> [Wallet]
    func refresh()

    func batchUpdate(closure: ([Wallet]) -> [Wallet])
    var objectWillChange: ObservableObjectPublisher { get }
}

extension WalletsRepositoryImpl: WalletsRepository {
    var statePublisher: AnyPublisher<LoadingState, Never> {
        $state.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var currentState: LoadingState {
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
