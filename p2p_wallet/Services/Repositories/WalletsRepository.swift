//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView_Combine
import Combine
import Foundation
import RxSwift // TODO: - Remove later
import SolanaSwift

protocol WalletsRepository: BECollectionViewModelType {
    var nativeWallet: Wallet? { get }
    func getWallets() -> [Wallet]
    func getError() -> Error?
    func reload()
    func toggleWalletVisibility(_ wallet: Wallet)
    func removeItem(where predicate: (Wallet) -> Bool) -> Wallet?
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?)
    func toggleIsHiddenWalletShown()
    var isHiddenWalletsShown: Bool { get set }
    func hiddenWallets() -> [Wallet]
    func refreshUI()

    func batchUpdate(closure: ([Wallet]) -> [Wallet])

    var dataPublisher: AnyPublisher<[Wallet], Never> { get }
    var statePublisher: AnyPublisher<BEFetcherState, Never> { get }

    @available(*, deprecated, message: "RxSwift will be removed soon")
    var dataObservable: Observable<[Wallet]> { get }

    @available(*, deprecated, message: "RxSwift will be removed soon")
    var stateObservable: Observable<BEFetcherState> { get }
}

extension WalletsViewModel: WalletsRepository {
    func getWallets() -> [Wallet] {
        data
    }

    func getError() -> Error? {
        error
    }

    var dataPublisher: AnyPublisher<[Wallet], Never> {
        $data.eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<BEFetcherState, Never> {
        $state.eraseToAnyPublisher()
    }

    @available(*, deprecated, message: "RxSwift will be removed soon")
    var dataObservable: Observable<[Wallet]> {
        $data.asObservable()
    }

    @available(*, deprecated, message: "RxSwift will be removed soon")
    var stateObservable: Observable<BEFetcherState> {
        $state.asObservable()
    }
}
