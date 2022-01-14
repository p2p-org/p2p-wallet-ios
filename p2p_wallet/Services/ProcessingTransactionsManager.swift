//
//  TransactionsManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/12/2020.
//

import Foundation
import RxSwift
import RxCocoa

class ProcessingTransactionsManager: ProcessingTransactionsRepository {
    // MARK: - Dependencies
    @Injected private var notificationsService: NotificationsServiceType
    @Injected private var handler: TransactionHandler
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var pricesService: PricesServiceType
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let transactionsSubject = BehaviorRelay<[SolanaSDK.ParsedTransaction]>(value: [])
    
    // MARK: - Methods
    func getProcessingTransactions() -> [SolanaSDK.ParsedTransaction] {
        transactionsSubject.value
    }
    
    func processingTransactionsObservable() -> Observable<[SolanaSDK.ParsedTransaction]> {
        transactionsSubject.asObservable()
    }
    
    func request(_ request: Single<ProcessTransactionResponseType>, transaction: SolanaSDK.ParsedTransaction, fees: [PayingFee]) -> Int {
        // modify blocktime
        var transaction = transaction
        transaction.blockTime = Date()
        
        // add pending transaction
        var transactions = transactionsSubject.value
        let index = transactions.count
        transactions.append(transaction)
        transactionsSubject.accept(transactions)
        
        // update balance before sending
        updateRepository(transactionIndex: index, fees: fees, isReversed: false)
        
        // request
        request
            .do(onSuccess: {[weak self] response in
                guard let response = response as? SolanaSDK.SwapResponse else {
                    return
                }
                self?.addNewWalletToRepository(transactionIndex: index, swapResponse: response)
            })
            // get signature
            .map { response -> String in
                if let swapResponse = response as? SolanaSDK.SwapResponse {
                    return swapResponse.transactionId
                }
                
                if let response = response as? SolanaSDK.TransactionID {
                    return response
                }
                
                throw SolanaSDK.Error.unknown
            }
            // update transaction status
            .do(onSuccess: {[weak self] signature in
                self?.batchUpdateTransaction(transactionIndex: index, modifier: { transaction in
                    var transaction = transaction
                    transaction.status = .processing(percent: 0)
                    transaction.signature = signature
                    return transaction
                })
            })
            // signature subscribe
            .flatMapCompletable{ signature in
                self.handler.observeTransactionCompletion(signature: signature)
                    .timeout(.seconds(60), scheduler: MainScheduler.instance)
                    .catch {_ in .empty()}
            }
            .observe(on: MainScheduler.instance)
            // transactionConfirmed
            .subscribe(onCompleted: { [weak self] in
                self?.updateTransactionStatus(transactionIndex: index, status: .confirmed)
            }, onError: {[weak self] error in
                self?.updateTransactionStatus(transactionIndex: index, status: .error(error.readableDescription))
                self?.updateRepository(transactionIndex: index, fees: fees, isReversed: true)
                
                // show alert
                self?.notificationsService.showInAppNotification(.error(L10n.errorSendingTransaction + ": " + error.readableDescription))
            })
            .disposed(by: disposeBag)
        
        return index
    }
    
    private func updateTransactionStatus(transactionIndex: Int, status: SolanaSDK.ParsedTransaction.Status)
    {
        if var transaction = transactionsSubject.value[safe: transactionIndex] {
            transaction.status = status
            var transactions = transactionsSubject.value
            transactions[transactionIndex] = transaction
            transactionsSubject.accept(transactions)
        }
    }
    
    private func batchUpdateTransaction(transactionIndex: Int, modifier: (SolanaSDK.ParsedTransaction) -> SolanaSDK.ParsedTransaction
    ) {
        if var transaction = transactionsSubject.value[safe: transactionIndex] {
            transaction = modifier(transaction)
            var transactions = transactionsSubject.value
            transactions[transactionIndex] = transaction
            transactionsSubject.accept(transactions)
        }
    }
    
    private func updateRepository(transactionIndex: Int, fees: [PayingFee], isReversed: Bool) {
        guard let tx = transactionsSubject.value[safe: transactionIndex],
              let transaction = tx.value
        else {
            return
        }
        
        // Send
        if let transaction = transaction as? SolanaSDK.TransferTransaction {
            walletsRepository.batchUpdate(closure: {
                var wallets = $0
                // update fromWallet
                if let fromWallet = transaction.source,
                   let amount = transaction.amount,
                    let index = wallets.firstIndex(where: {$0.pubkey == fromWallet.pubkey})
                {
                    if isReversed {
                        wallets[index].increaseBalance(diffInLamports: amount.toLamport(decimals: fromWallet.token.decimals))
                    } else {
                        wallets[index].decreaseBalance(diffInLamports: amount.toLamport(decimals: fromWallet.token.decimals))
                    }
                }
                
                // update toWallet (if send to different wallet of THIS account)
                if let toWallet = transaction.destination,
                   let amount = transaction.amount,
                    let index = wallets.firstIndex(where: {$0.pubkey == toWallet.pubkey})
                {
                    if isReversed {
                        wallets[index].decreaseBalance(diffInLamports: amount.toLamport(decimals: toWallet.token.decimals))
                    } else {
                        wallets[index].increaseBalance(diffInLamports: amount.toLamport(decimals: toWallet.token.decimals))
                    }
                    
                }
                
                // update SOL wallet (minus fee)
                for fee in fees {
                    if let index = wallets.firstIndex(where: {$0.token.address == fee.token.address})
                    {
                        if isReversed {
                            wallets[index].increaseBalance(diffInLamports: fee.lamports)
                        } else {
                            wallets[index].decreaseBalance(diffInLamports: fee.lamports)
                        }
                    }
                }
                
                return wallets
            })
        }
        
        // Close account
        else if let transaction = transaction as? SolanaSDK.CloseAccountTransaction {
            walletsRepository.batchUpdate(closure: {
                var wallets = $0
                var convertedAmount = transaction.reimbursedAmount ?? 0
                
                if let wallet = transaction.closedWallet {
                    // remove closed wallet
                    if isReversed {
                        wallets.append(wallet)
                    } else {
                        wallets.removeAll(where: {$0.pubkey == wallet.pubkey})
                    }
                    
                    // if closing non-native Solana wallet, then convert its balances and send it to native Solana wallet
                    if wallet.token.symbol == "SOL" && !wallet.token.isNative {
                        if isReversed {
                            convertedAmount -= wallet.amount ?? 0
                        } else {
                            convertedAmount += wallet.amount ?? 0
                        }
                    }
                }

                // update native solana wallet
                if let index = wallets.firstIndex(where: {$0.isNativeSOL})
                {
                    wallets[index].updateBalance(diff: convertedAmount)
                }

                return wallets
            })
        }
        
        // Swap
        else if let transaction = transaction as? SolanaSDK.SwapTransaction
        {
            walletsRepository.batchUpdate(closure: {
                var wallets = $0

                // update source wallet
                if let sourceWallet = transaction.source,
                   let index = wallets.firstIndex(where: {$0.pubkey == sourceWallet.pubkey}),
                   let change = transaction.sourceAmount?.toLamport(decimals: sourceWallet.token.decimals)
                {
                    if isReversed {
                        wallets[index].increaseBalance(diffInLamports: change)
                    } else {
                        wallets[index].decreaseBalance(diffInLamports: change)
                    }
                }

                // update destination wallet if exists
                if let destinationWallet = transaction.destination,
                   let index = wallets.firstIndex(where: {$0.pubkey == destinationWallet.pubkey}),
                   let change = transaction.destinationAmount?.toLamport(decimals: destinationWallet.token.decimals)
                {
                    if isReversed {
                        wallets[index].decreaseBalance(diffInLamports: change)
                    } else {
                        wallets[index].increaseBalance(diffInLamports: change)
                    }
                    
                }

                // update sol wallet (minus fee)
                for fee in fees {
                    if let index = wallets.firstIndex(where: {$0.token.address == fee.token.address})
                    {
                        if isReversed {
                            wallets[index].increaseBalance(diffInLamports: fee.lamports)
                        } else {
                            wallets[index].decreaseBalance(diffInLamports: fee.lamports)
                        }
                    }
                }

                return wallets
            })
        }
    }
    
    private func addNewWalletToRepository(transactionIndex: Int, swapResponse: SolanaSDK.SwapResponse) {
        guard let tx = transactionsSubject.value[safe: transactionIndex],
              let transaction = tx.value as? SolanaSDK.SwapTransaction,
              let wallet = transaction.destination
        else {
            return
        }
        // add new wallet if destination is a new wallet
        walletsRepository.batchUpdate { wallets in
            var wallets = wallets
            var wallet = wallet
            if !wallets.contains(where: {$0.token.symbol == wallet.token.symbol}) {
                wallet.pubkey = swapResponse.newWalletPubkey
                wallet.lamports = transaction.destinationAmount?.toLamport(decimals: wallet.token.decimals)
                wallet.price = pricesService.currentPrice(for: wallet.token.symbol)
                wallets.append(wallet)
            }
            
            return wallets
        }
    }
}
