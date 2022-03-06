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
    func observeTransaction(transactionIndex: TransactionIndex) -> Observable<PendingTransaction?>
    func areSomeTransactionsInProgress() -> Bool
    
    func observeProcessingTransactions(forAccount account: String) -> Observable<[SolanaSDK.ParsedTransaction]>
    func getProccessingTransactions(of account: String) -> [SolanaSDK.ParsedTransaction]
}

class TransactionHandler: TransactionHandlerType {
    @Injected var notificationsService: NotificationsServiceType
    @Injected var apiClient: ProcessTransactionAPIClient
    @Injected var walletsRepository: WalletsRepository
    @Injected var pricesService: PricesServiceType
    
    let locker = NSLock()
    let disposeBag = DisposeBag()
    let transactionsSubject = BehaviorRelay<[PendingTransaction]>(value: [])
    
    func sendTransaction(
        _ processingTransaction: ProcessingTransactionType
    ) -> TransactionIndex {
        // get index to return
        let txIndex = transactionsSubject.value.count
        
        // add to processing
        var value = transactionsSubject.value
        value.append(
            .init(transactionId: nil, sentAt: Date(), rawTransaction: processingTransaction, status: .sending)
        )
        transactionsSubject.accept(value)
        
        // process
        sendAndObserve(index: txIndex, processingTransaction: processingTransaction)
        
        return txIndex
    }
    
    func observeTransaction(
        transactionIndex: TransactionIndex
    ) -> Observable<PendingTransaction?> {
        transactionsSubject.map {$0[safe: transactionIndex]}
    }
    
    func areSomeTransactionsInProgress() -> Bool {
        transactionsSubject.value.contains(where: {$0.status.isProcessing})
    }
    
    func observeProcessingTransactions(
        forAccount account: String
    ) -> Observable<[SolanaSDK.ParsedTransaction]> {
        transactionsSubject
            .map {[weak self] _ in self?.getProccessingTransactions(of: account) ?? []}
            .asObservable()
    }
    
    func getProccessingTransactions(
        of account: String
    ) -> [SolanaSDK.ParsedTransaction] {
        transactionsSubject.value
            .compactMap { pt -> SolanaSDK.ParsedTransaction? in
                // status
                let status: SolanaSDK.ParsedTransaction.Status
                
                switch pt.status {
                case .sending:
                    status = .requesting
                case .confirmed:
                    status = .processing(percent: 0)
                case .finalized:
                    status = .confirmed
                case .error(let error):
                    status = .error(error.readableDescription)
                }
                
                let signature = pt.transactionId
                
                var value: AnyHashable?
                let amountInFiat: Double?
                let fee: UInt64?
                
                switch pt.rawTransaction {
                case let transaction as ProcessTransaction.SendTransaction:
                    if transaction.sender.pubkey == account ||
                        transaction.receiver.address == account ||
                        transaction.authority == account
                    {
                        let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
                        value = SolanaSDK.TransferTransaction(
                            source: transaction.sender,
                            destination: Wallet(pubkey: transaction.receiver.address, lamports: 0, token: transaction.sender.token),
                            authority: walletsRepository.nativeWallet?.pubkey,
                            destinationAuthority: nil,
                            amount: amount,
                            myAccount: transaction.sender.pubkey
                        )
                        amountInFiat = amount * pricesService.currentPrice(for: transaction.sender.token.symbol)?.value
                        fee = transaction.feeInSOL
                    } else {
                        return nil
                    }
                case let transaction as ProcessTransaction.OrcaSwapTransaction:
                    if transaction.sourceWallet.pubkey == account ||
                        transaction.destinationWallet.pubkey == account ||
                        transaction.authority == account
                    {
                        value = SolanaSDK.SwapTransaction(
                            source: transaction.sourceWallet,
                            sourceAmount: transaction.amount,
                            destination: transaction.destinationWallet,
                            destinationAmount: transaction.estimatedAmount,
                            myAccountSymbol: nil
                        )
                        amountInFiat = transaction.amount * pricesService.currentPrice(for: transaction.sourceWallet.token.symbol)?.value
                        fee = transaction.fees.networkFees?.total
                    } else {
                        return nil
                    }
                default:
                    return nil
                }
                
                return .init(status: status, signature: signature, value: value, amountInFiat: amountInFiat, slot: 0, blockTime: pt.sentAt, fee: fee, blockhash: nil)
            }
    }
    
    // MARK: - Helpers
    
    
    
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
