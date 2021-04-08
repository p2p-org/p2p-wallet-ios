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
    let pricesRepository: PricesRepository
    let disposeBag = DisposeBag()
    
    init(
        account: String,
        repository: TransactionsRepository,
        pricesRepository: PricesRepository
    ) {
        self.account = account
        self.repository = repository
        self.pricesRepository = pricesRepository
        super.init(isPaginationEnabled: true, limit: 10)
    }
    
    override func bind() {
        pricesRepository.pricesObservable()
            .subscribe(onNext: {[weak self] _ in
                self?.updatePrices()
            })
            .disposed(by: disposeBag)
    }
    
    override func createRequest() -> Single<[SolanaSDK.AnyTransaction]> {
        repository.getTransactionsHistory(
            account: account,
            before: before,
            limit: limit
        )
            .map { [weak self] newData in
                guard let data = self?.updatedTransactionsWithPrices(transactions: newData)
                else {return newData}
                return data
            }
            .do(
                afterSuccess: {[weak self] transactions in
                    self?.before = transactions.last?.signature
                }
            )
    }
    
    override func flush() {
        before = nil
        super.flush()
    }
    
    // MARK: - Helpers
    private func updatePrices() {
        let newData = updatedTransactionsWithPrices(transactions: data)
        overrideData(by: newData)
    }
    
    private func updatedTransactionsWithPrices(transactions: [SolanaSDK.AnyTransaction]) -> [SolanaSDK.AnyTransaction]
    {
        var transactions = transactions
        for index in 0..<transactions.count {
            transactions[index] = updatedTransactionWithPrice(transaction: transactions[index])
        }
        return transactions
    }
    
    private func updatedTransactionWithPrice(
        transaction: SolanaSDK.AnyTransaction
    ) -> SolanaSDK.AnyTransaction {
        guard let price = pricesRepository.currentPrice(for: transaction.symbol)
        else {return transaction}
        
        var transaction = transaction
        transaction.amountInFiat = transaction.amount * price.value
        
        return transaction
    }
}
