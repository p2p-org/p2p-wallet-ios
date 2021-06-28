//
//  ProcessingTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/06/2021.
//

import Foundation
import RxSwift

protocol ProcessingTransactionsRepository {
    func processingTransactionsObservable() -> Observable<[ParsedTransaction]>
    func getProcessingTransactions() -> [ParsedTransaction]
    func process(transaction: SolanaSDK.AnyTransaction)
}

extension ProcessingTransactionsRepository {
    func areSomeTransactionsInProgress() -> Bool {
        getProcessingTransactions().filter {$0.status != .confirmed}.count > 0
    }
}
