//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView_Combine
import Combine
import Foundation
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
    var isHiddenWalletsShown: CurrentValueSubject<Bool, Never> { get }
    func hiddenWallets() -> [Wallet]
    func refreshUI()

    func batchUpdate(closure: ([Wallet]) -> [Wallet])
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
}
