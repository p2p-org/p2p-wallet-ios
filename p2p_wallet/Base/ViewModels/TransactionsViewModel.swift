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
    let accountSymbol: String
    var before: String?
    let repository: TransactionsRepository
    let pricesRepository: PricesRepository
    let disposeBag = DisposeBag()
    
    init(
        account: String,
        accountSymbol: String,
        repository: TransactionsRepository,
        pricesRepository: PricesRepository
    ) {
        self.account = account
        self.accountSymbol = accountSymbol
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
            accountSymbol: accountSymbol,
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
    
    override func join(_ newItems: [SolanaSDK.AnyTransaction]) -> [SolanaSDK.AnyTransaction] {
        let filteredItems = newItems
            .filter {
                // filter out undefined Transfer transaction
                if let transferTransaction = $0.value as? SolanaSDK.TransferTransaction,
                   transferTransaction.transferType == nil
                {
                    return false
                }
                return true
            }
        return super.join(filteredItems)
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
