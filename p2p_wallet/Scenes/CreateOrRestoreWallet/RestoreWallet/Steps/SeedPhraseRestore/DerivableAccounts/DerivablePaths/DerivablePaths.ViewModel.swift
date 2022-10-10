//
//  DerivablePaths.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import BECollectionView
import Foundation
import RxSwift
import SolanaSwift

extension DerivablePaths {
    class ViewModel: BEListViewModel<SelectableDerivablePath> {
        private let currentPath: DerivablePath
        init(currentPath: DerivablePath) {
            self.currentPath = currentPath
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        override func createRequest() -> Single<[SelectableDerivablePath]> {
            let paths = DerivablePath.DerivableType
                .allCases
                .map { DerivablePath(type: $0, walletIndex: 0, accountIndex: 0) }
                .map {
                    SelectableDerivablePath(
                        path: $0,
                        isSelected: $0 == currentPath
                    )
                }
            return .just(paths)
        }
    }
}
