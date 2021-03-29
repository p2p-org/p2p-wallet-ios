//
//  OtherWalletsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import BECollectionView
import RxSwift

class OtherWalletsViewModel: BEListViewModel<Wallet> {
    override func createRequest() -> Single<[Wallet]> {
        Single<[Wallet]>.create {observer in
            DispatchQueue.global(qos: .background).async {
                let wallets = SolanaSDK.Token.getSupportedTokens(network: Defaults.network)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
                observer(.success(wallets))
            }
            return Disposables.create()
        }
    }
}
