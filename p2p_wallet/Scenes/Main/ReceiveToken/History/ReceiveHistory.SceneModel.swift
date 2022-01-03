//
// Created by Giang Long Tran on 03.01.22.
//

import Foundation
import BECollectionView
import SolanaSwift
import RxSwift

extension ReceiveHistory {
    class ViewModel {
        private let walletRepository: WalletsRepository
        private let history: TransactionsViewModel
    }
}
