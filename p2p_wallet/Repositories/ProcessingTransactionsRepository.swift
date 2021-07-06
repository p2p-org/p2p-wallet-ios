//
//  ProcessingTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/06/2021.
//

import Foundation
import RxSwift

protocol ProcessingTransactionsRepository: AnyObject {
    typealias RequestIndex = Int
    func processingTransactionsObservable() -> Observable<[SolanaSDK.ParsedTransaction]>
    func getProcessingTransactions() -> [SolanaSDK.ParsedTransaction]
    func request(_ request: Single<ProcessTransactionResponseType>, transaction: SolanaSDK.ParsedTransaction, fee: SolanaSDK.Lamports) -> RequestIndex
}

extension ProcessingTransactionsRepository {
    func areSomeTransactionsInProgress() -> Bool {
        getProcessingTransactions().filter {$0.isProcessing}.count > 0
    }
}
