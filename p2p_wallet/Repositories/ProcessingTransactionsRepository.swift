//
//  ProcessingTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/06/2021.
//

import Foundation
import RxSwift

protocol ProcessingTransactionsRepository {
    func processingTransactionsObservable() -> Observable<[ProcessingTransaction]>
    func getProcessingTransactions() -> [ProcessingTransaction]
    func process(transaction: SolanaSDK.AnyTransaction)
}
