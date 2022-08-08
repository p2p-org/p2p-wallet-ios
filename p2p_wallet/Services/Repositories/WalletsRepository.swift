//
//  WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import BECollectionView_Combine
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
    var isHiddenWalletsShown: Bool { get set }
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
}
