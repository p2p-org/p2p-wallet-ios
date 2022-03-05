//
//  TransactionHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import Foundation
import RxSwift
import RxCocoa

protocol TransactionHandlerType {
    typealias TransactionIndex = Int
    func sendTransaction(_ processingTransaction: ProcessingTransactionType) -> TransactionIndex
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PT.TransactionInfo?>
    func areSomeTransactionsInProgress() -> Bool
    func processingTransactionsObservable() -> Observable<[PT.TransactionInfo]>
}

class TransactionHandler: TransactionHandlerType {
    @Injected private var notificationsService: NotificationsServiceType
    @Injected private var apiClient: ProcessTransactionAPIClient
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var pricesService: PricesServiceType
    
    private let locker = NSLock()
    private let disposeBag = DisposeBag()
    private let transactionsSubject = BehaviorRelay<[PT.TransactionInfo]>(value: [])
    
    func sendTransaction(_ processingTransaction: ProcessingTransactionType) -> TransactionIndex
    {
        // get index to return
        let txIndex = transactionsSubject.value.count
        
        // add to processing
        var value = transactionsSubject.value
        value.append(
            .init(transactionId: nil, rawTransaction: processingTransaction, status: .sending)
        )
        transactionsSubject.accept(value)
        
        // process
        sendAndObserve(index: txIndex, processingTransaction: processingTransaction)
        
        return txIndex
    }
    
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PT.TransactionInfo?>
    {
        transactionsSubject.map {$0[safe: transactionIndex]}
    }
    
    func areSomeTransactionsInProgress() -> Bool {
        transactionsSubject.value.contains(where: {$0.status.isProcessing})
    }
    
    func processingTransactionsObservable() -> Observable<[PT.TransactionInfo]> {
        transactionsSubject.asObservable()
    }
    
    // MARK: - Helpers
    private func sendAndObserve(
        index: TransactionIndex,
        processingTransaction: ProcessingTransactionType
    ) {
        processingTransaction.createRequest()
            .subscribe(onSuccess: { [weak self] transactionID in
                guard let self = self else {return}
                
                self.updateTransactionAtIndex(index) { _ in
                    .init(
                        transactionId: transactionID,
                        rawTransaction: processingTransaction,
                        status: .confirmed(0)
                    )
                }
                
                self.observe(index: index, transactionId: transactionID)
            }, onFailure: { [weak self] error in
                guard let self = self else {return}
                
                self.updateTransactionAtIndex(index) { currentValue in
                    var info = currentValue
                    info.status = .error(error)
                    return info
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func observe(index: TransactionIndex, transactionId: String) {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        
        apiClient.getSignatureStatus(signature: transactionId, configs: nil)
            .subscribe(on: scheduler)
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { [weak self] status in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                let txStatus: PT.TransactionInfo.TransactionStatus
                
                if status.confirmations == nil || status.confirmationStatus == "finalized" {
                    txStatus = .finalized
                } else {
                    txStatus = .confirmed(Int(status.confirmations ?? 0))
                }
                
                self.updateTransactionAtIndex(index) { currentValue in
                    var value = currentValue
                    value.status = txStatus
                    return value
                }
            })
            .observe(on: scheduler)
            .map {$0.confirmations == nil || $0.confirmationStatus == "finalized"}
            .flatMapCompletable { confirmed in
                if confirmed {return .empty()}
                throw PT.Error.notEnoughNumberOfConfirmations
            }
            .retry(maxAttempts: .max, delayInSeconds: 1)
            .timeout(.seconds(60), scheduler: scheduler)
            .subscribe()
            .disposed(by: disposeBag)
            
    }
    
    @discardableResult
    private func updateTransactionAtIndex(
        _ index: TransactionIndex,
        update: (PT.TransactionInfo) -> PT.TransactionInfo
    ) -> Bool {
        var value = transactionsSubject.value
        
        if let currentValue = value[safe: index] {
            let newValue = update(currentValue)
            value[index] = newValue
            locker.lock()
            transactionsSubject.accept(value)
            locker.unlock()
            return true
        }
        
        return false
    }
    
//    private func updateRepository(transactionIndex: Int, fees: [PayingFee], isReversed: Bool) {
//        guard let tx = transactionsSubject.value[safe: transactionIndex]
//        else {
//            return
//        }
//
//        switch tx.rawTransaction {
//        case let transaction as PT.SendTransaction:
//        case let transaction as PT.OrcaSwapTransaction:
//        case let transaction as PT.CloseTransaction:
//        }
//
//        // Send
//        if let transaction = transaction as? SolanaSDK.TransferTransaction {
//            walletsRepository.batchUpdate(closure: {
//                var wallets = $0
//                // update fromWallet
//                if let fromWallet = transaction.source,
//                   let amount = transaction.amount,
//                    let index = wallets.firstIndex(where: {$0.pubkey == fromWallet.pubkey})
//                {
//                    if isReversed {
//                        wallets[index].increaseBalance(diffInLamports: amount.toLamport(decimals: fromWallet.token.decimals))
//                    } else {
//                        wallets[index].decreaseBalance(diffInLamports: amount.toLamport(decimals: fromWallet.token.decimals))
//                    }
//                }
//
//                // update toWallet (if send to different wallet of THIS account)
//                if let toWallet = transaction.destination,
//                   let amount = transaction.amount,
//                    let index = wallets.firstIndex(where: {$0.pubkey == toWallet.pubkey})
//                {
//                    if isReversed {
//                        wallets[index].decreaseBalance(diffInLamports: amount.toLamport(decimals: toWallet.token.decimals))
//                    } else {
//                        wallets[index].increaseBalance(diffInLamports: amount.toLamport(decimals: toWallet.token.decimals))
//                    }
//
//                }
//
//                // update SOL wallet (minus fee)
//                for fee in fees {
//                    if let index = wallets.firstIndex(where: {$0.token.address == fee.token.address})
//                    {
//                        if isReversed {
//                            wallets[index].increaseBalance(diffInLamports: fee.lamports)
//                        } else {
//                            wallets[index].decreaseBalance(diffInLamports: fee.lamports)
//                        }
//                    }
//                }
//
//                return wallets
//            })
//        }
//
//        // Close account
//        else if let transaction = transaction as? SolanaSDK.CloseAccountTransaction {
//            walletsRepository.batchUpdate(closure: {
//                var wallets = $0
//                var convertedAmount = transaction.reimbursedAmount ?? 0
//
//                if let wallet = transaction.closedWallet {
//                    // remove closed wallet
//                    if isReversed {
//                        wallets.append(wallet)
//                    } else {
//                        wallets.removeAll(where: {$0.pubkey == wallet.pubkey})
//                    }
//
//                    // if closing non-native Solana wallet, then convert its balances and send it to native Solana wallet
//                    if wallet.token.symbol == "SOL" && !wallet.token.isNative {
//                        if isReversed {
//                            convertedAmount -= wallet.amount ?? 0
//                        } else {
//                            convertedAmount += wallet.amount ?? 0
//                        }
//                    }
//                }
//
//                // update native solana wallet
//                if let index = wallets.firstIndex(where: {$0.isNativeSOL})
//                {
//                    wallets[index].updateBalance(diff: convertedAmount)
//                }
//
//                return wallets
//            })
//        }
//
//        // Swap
//        else if let transaction = transaction as? SolanaSDK.SwapTransaction
//        {
//            walletsRepository.batchUpdate(closure: {
//                var wallets = $0
//
//                // update source wallet
//                if let sourceWallet = transaction.source,
//                   let index = wallets.firstIndex(where: {$0.pubkey == sourceWallet.pubkey}),
//                   let change = transaction.sourceAmount?.toLamport(decimals: sourceWallet.token.decimals)
//                {
//                    if isReversed {
//                        wallets[index].increaseBalance(diffInLamports: change)
//                    } else {
//                        wallets[index].decreaseBalance(diffInLamports: change)
//                    }
//                }
//
//                // update destination wallet if exists
//                if let destinationWallet = transaction.destination,
//                   let index = wallets.firstIndex(where: {$0.pubkey == destinationWallet.pubkey}),
//                   let change = transaction.destinationAmount?.toLamport(decimals: destinationWallet.token.decimals)
//                {
//                    if isReversed {
//                        wallets[index].decreaseBalance(diffInLamports: change)
//                    } else {
//                        wallets[index].increaseBalance(diffInLamports: change)
//                    }
//
//                }
//
//                // update sol wallet (minus fee)
//                for fee in fees {
//                    if let index = wallets.firstIndex(where: {$0.token.address == fee.token.address})
//                    {
//                        if isReversed {
//                            wallets[index].increaseBalance(diffInLamports: fee.lamports)
//                        } else {
//                            wallets[index].decreaseBalance(diffInLamports: fee.lamports)
//                        }
//                    }
//                }
//
//                return wallets
//            })
//        }
//    }
//
//    private func addNewWalletToRepository(transactionIndex: Int, swapResponse: SolanaSDK.SwapResponse) {
//        guard let tx = transactionsSubject.value[safe: transactionIndex],
//              let transaction = tx.value as? SolanaSDK.SwapTransaction,
//              let wallet = transaction.destination
//        else {
//            return
//        }
//        // add new wallet if destination is a new wallet
//        walletsRepository.batchUpdate { wallets in
//            var wallets = wallets
//            var wallet = wallet
//            if !wallets.contains(where: {$0.token.symbol == wallet.token.symbol}) {
//                wallet.pubkey = swapResponse.newWalletPubkey
//                wallet.lamports = transaction.destinationAmount?.toLamport(decimals: wallet.token.decimals)
//                wallet.price = pricesService.currentPrice(for: wallet.token.symbol)
//                wallets.append(wallet)
//            }
//
//            return wallets
//        }
//    }
}
