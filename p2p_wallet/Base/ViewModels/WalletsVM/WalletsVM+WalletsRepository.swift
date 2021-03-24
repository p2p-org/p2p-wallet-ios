//
//  WalletsVM+WalletsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import RxSwift
import BECollectionView

extension WalletsVM: WalletsRepository {
    func getWallets() -> [Wallet] {
        items
    }
    
    func stateObservable() -> Observable<BEFetcherState> {
        state.asObservable()
            .map { state -> BEFetcherState in
                switch state {
                case .initializing:
                    return .initializing
                case .loading:
                    return .loading
                case .loaded:
                    return .loaded
                case .error:
                    return .error
                }
            }
    }
    
    func getError() -> Error? {
        switch state.value {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
    
    
}
