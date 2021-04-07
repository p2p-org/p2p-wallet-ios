//
//  TransactionsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift

class TransactionsViewModel: BEListViewModel<SolanaSDK.AnyTransaction> {
    let account: String
    var before: String?
    let repository: TransactionsRepository
    
    init(account: String, repository: TransactionsRepository) {
        self.account = account
        self.repository = repository
        super.init(isPaginationEnabled: true, limit: 10)
    }
    
    override func createRequest() -> Single<[SolanaSDK.AnyTransaction]> {
        repository.getTransactionsHistory(
            account: account,
            before: before,
            limit: limit
        )
            .do(
                afterSuccess: {transactions in
                    self.before = transactions.last?.signature
                }
            )
    }
    
    override func flush() {
        before = nil
        super.flush()
    }
}
