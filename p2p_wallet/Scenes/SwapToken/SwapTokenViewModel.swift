//
//  SwapTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LazySubject

enum SwapTokenNavigatableScene {
    case chooseSourceWallet
    case chooseDestinationWallet
    case chooseSlippage
    case sendTransaction
    case processTransaction(signature: String)
    case transactionError(_ error: Error)
}

class SwapTokenViewModel {
    // MARK: - Constants
    typealias Pool = SolanaSDK.Pool
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let solanaSDK: SolanaSDK
    let transactionManager: TransactionsManager
    let wallets: [Wallet]
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<SwapTokenNavigatableScene>()
    lazy var pools = LazySubject<[Pool]>(request: solanaSDK.getSwapPools())
    let currentPool = BehaviorRelay<Pool?>(value: nil)
    let minimumReceiveAmount = BehaviorRelay<Double?>(value: nil)
    let errorSubject = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Input
    let sourceAmountInput = BehaviorRelay<String?>(value: nil)
    let destinationAmountInput = BehaviorRelay<String?>(value: nil)
    let sourceWallet = BehaviorRelay<Wallet?>(value: nil)
    let destinationWallet = BehaviorRelay<Wallet?>(value: nil)
    let slippage = BehaviorRelay<Double>(value: Defaults.slippage)
    let isReversedExchangeRate = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializer
    init(solanaSDK: SolanaSDK, transactionManager: TransactionsManager, wallets: [Wallet], fromWallet: Wallet? = nil, toWallet: Wallet? = nil) {
        self.solanaSDK = solanaSDK
        self.transactionManager = transactionManager
        self.wallets = wallets
        pools.reload()
        
        sourceWallet.accept(fromWallet ?? wallets.first(where: {$0.symbol == "SOL"}))
        destinationWallet.accept(toWallet)
        bind()
    }
    
    // MARK: - Binding
    func bind() {
        let poolsLoaded =
        pools.observable
            .filter {$0 == .loaded}
            .map {_ in self.pools.value}
        
        // current pool
        Observable.combineLatest(
            poolsLoaded,
            sourceWallet.distinctUntilChanged(),
            destinationWallet.distinctUntilChanged()
        )
            .map {(pools, sourceWallet, destinationWallet) in
                pools?.matchedPool(
                    sourceMint: sourceWallet?.mintAddress,
                    destinationMint: destinationWallet?.mintAddress
                )
            }
            .bind(to: currentPool)
            .disposed(by: disposeBag)
        
        // estimated amount
        let estimatedAmountLamports = Observable.combineLatest(
            currentPool.distinctUntilChanged(),
            sourceAmountInput.distinctUntilChanged()
        )
            .map {(pool, amount) -> UInt64? in
                guard let amount = amount.double,
                      amount > 0,
                      let sourceDecimals = self.sourceWallet.value?.decimals,
                      let estimatedAmountLamports = pool?.estimatedAmount(forInputAmount: amount.toLamport(decimals: sourceDecimals))
                else {return nil}
                return estimatedAmountLamports
            }
            
        estimatedAmountLamports
            .map {lamports -> Double? in
                guard let destinationDecimals = self.destinationWallet.value?.decimals
                else {return nil}
                return lamports?.convertToBalance(decimals: destinationDecimals)
            }
            .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: nil)}
            .bind(to: destinationAmountInput)
            .disposed(by: disposeBag)
        
        // TODO: Reverse: estimated amount to input amount
        
        // minimum receive
        Observable.combineLatest(
            estimatedAmountLamports.distinctUntilChanged(),
            slippage.distinctUntilChanged()
        )
            .map {(estimatedAmountLamports, slippage) -> Double? in
                guard let estimatedAmountLamports = estimatedAmountLamports,
                      let lamports = self.currentPool.value?.minimumReceiveAmount(estimatedAmount: estimatedAmountLamports, slippage: slippage),
                      let destinationDecimals = self.destinationWallet.value?.decimals
                else {return nil}
                return lamports.convertToBalance(decimals: destinationDecimals)
            }
            .bind(to: minimumReceiveAmount)
            .disposed(by: disposeBag)
        
        // error subject
        Observable.combineLatest(
            pools.observable,
            currentPool,
            sourceWallet,
            destinationWallet,
            sourceAmountInput,
            slippage
        )
            .map {_, pool, sourceWallet, destinationWallet, sourceAmountInput, slippage -> String? in
                var errorText: String?
                if pool != nil {
                    // supported
                    if let input = sourceAmountInput.double {
                        if input <= 0 {
                            errorText = L10n.amountIsNotValid
                        } else if input > sourceWallet?.amount {
                            errorText = L10n.insufficientFunds
                        } else if !self.isSlippageValid(slippage: slippage) {
                            errorText = L10n.slippageIsnTValid
                        }
                    }
                } else {
                    // unsupported
                    if let pools = self.pools.value,
                       !pools.isEmpty
                    {
                        if let sourceWallet = sourceWallet,
                           let destinationWallet = destinationWallet
                        {
                            if sourceWallet.symbol == destinationWallet.symbol {
                                errorText = L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.symbol)
                            } else {
                                errorText = L10n.swappingFromToIsCurrentlyUnsupported(sourceWallet.symbol, destinationWallet.symbol)
                            }
                        }
                    } else {
                        errorText = L10n.swappingIsCurrentlyUnavailable
                    }
                }
                return errorText
            }
            .bind(to: errorSubject)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    func isSlippageValid(slippage: Double) -> Bool {
        slippage <= 0.2 && slippage > 0
    }
    
    // MARK: - Actions
    @objc func useAllBalance() {
        sourceAmountInput.accept(sourceWallet.value?.amount?.toString(maximumFractionDigits: 9, groupingSeparator: nil))
    }
    
    @objc func chooseSourceWallet() {
        navigationSubject.onNext(.chooseSourceWallet)
    }
    
    @objc func chooseDestinationWallet() {
        navigationSubject.onNext(.chooseDestinationWallet)
    }
    
    @objc func swapSourceAndDestination() {
        let tempWallet = sourceWallet.value
        sourceWallet.accept(destinationWallet.value)
        destinationWallet.accept(tempWallet)
    }
    
    @objc func reverseExchangeRate() {
        isReversedExchangeRate.accept(!isReversedExchangeRate.value)
    }
    
    @objc func chooseSlippage() {
        navigationSubject.onNext(.chooseSlippage)
    }
    
    @objc func swap() {
        navigationSubject.onNext(.sendTransaction)
        guard let sourceWallet = sourceWallet.value,
              let sourcePubkey = try? SolanaSDK.PublicKey(string: sourceWallet.pubkey ?? ""),
              let sourceMint = try? SolanaSDK.PublicKey(string: sourceWallet.mintAddress),
              let destinationWallet = destinationWallet.value,
              let destinationMint = try? SolanaSDK.PublicKey(string: destinationWallet.mintAddress),
              
              let sourceDecimals = sourceWallet.decimals,
              let amountDouble = sourceAmountInput.value.double
        else {
            navigationSubject.onNext(.transactionError(SolanaSDK.Error.invalidRequest()))
            return
        }
        
        let lamports = amountDouble.toLamport(decimals: sourceDecimals)
        let destinationPubkey = try? SolanaSDK.PublicKey(string: destinationWallet.pubkey ?? "")
        
        solanaSDK.swap(
            pool: currentPool.value,
            source: sourcePubkey,
            sourceMint: sourceMint,
            destination: destinationPubkey,
            destinationMint: destinationMint,
            slippage: slippage.value,
            amount: lamports
        )
            .subscribe(onSuccess: { signature in
                self.navigationSubject.onNext(.processTransaction(signature: signature))
                let transaction = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: -amountDouble,
                    symbol: sourceWallet.symbol,
                    status: .processing
                )
                self.transactionManager.process(transaction)
                
                let transaction2 = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: +(self.destinationAmountInput.value.double ?? 0),
                    symbol: destinationWallet.symbol,
                    status: .processing
                )
                self.transactionManager.process(transaction2)
            }, onError: {error in
                self.navigationSubject.onNext(.transactionError(error))
            })
            .disposed(by: disposeBag)
    }
}
