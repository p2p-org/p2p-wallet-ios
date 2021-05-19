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
        let paths = SolanaSDK.DerivablePath.allCases
            .map {
                SelectableDerivablePath(
                    path: $0,
                    isSelected: $0 == currentPath
                )
            }
        return .just(paths)
    }
}
