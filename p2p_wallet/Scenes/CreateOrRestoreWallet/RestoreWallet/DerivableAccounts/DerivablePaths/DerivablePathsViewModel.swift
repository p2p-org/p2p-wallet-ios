//
//  DerivablePathsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation
import BECollectionView
import RxSwift

class DerivablePathsViewModel: BEListViewModel<SelectableDerivablePath> {
    private let currentPath: SolanaSDK.DerivablePath
    init(currentPath: SolanaSDK.DerivablePath) {
        self.currentPath = currentPath
    }
    
    override func createRequest() -> Single<[SelectableDerivablePath]> {
        let paths = SolanaSDK.DerivablePath.DerivableType
            .allCases
            .map {SolanaSDK.DerivablePath(type: $0, walletIndex: 0, accountIndex: 0)}
            .map {
                SelectableDerivablePath(
                    path: $0,
                    isSelected: $0 == currentPath
                )
            }
        return .just(paths)
    }
}
