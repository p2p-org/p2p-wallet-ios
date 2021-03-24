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
}
