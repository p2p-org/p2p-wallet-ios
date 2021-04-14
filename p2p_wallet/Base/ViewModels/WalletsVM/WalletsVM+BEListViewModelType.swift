//
//  WalletsVM+BEListViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import BECollectionView

extension WalletsVM: BEListViewModelType {
    var currentState: BEFetcherState {
        switch state.value {
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
    
    func convertDataToAnyHashable() -> [AnyHashable] {
        data as [AnyHashable]
    }
    
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?) {
        switch state {
        case .initializing:
            self.state.accept(.initializing)
        case .loading:
            self.state.accept(.loading)
        case .loaded:
            guard let data = data as? [Wallet] else {return}
            self.data = data
            self.state.accept(.loaded(data))
        case .error:
            self.state.accept(.error(SolanaSDK.Error.unknown))
        }
    }
}
