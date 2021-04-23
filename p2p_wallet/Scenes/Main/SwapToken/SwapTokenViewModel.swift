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
import Action

enum SwapTokenNavigatableScene {
    case chooseSourceWallet
    case chooseDestinationWallet
    case chooseSlippage
    case processTransaction
    case loading(Bool)
}

class SwapTokenViewModel {
    // MARK: - Constants
    typealias Pool = SolanaSDK.Pool
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    let solanaSDK: SolanaSDK
    let transactionManager: TransactionsManager
    let wallets: [Wallet]
    lazy var processTransactionViewModel: ProcessTransactionViewModel = {
        let viewModel = ProcessTransactionViewModel(transactionsManager: transactionManager)
        viewModel.tryAgainAction = CocoaAction {
            self.swap()
            return .just(())
        }
        return viewModel
    }()
    
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
        Observable.combineLatest(
            currentPool.distinctUntilChanged(),
            sourceAmountInput.distinctUntilChanged()
        )
            .map {[weak self] in self?.calculateEstimatedAmount(forInputAmount: $1.double)}
            .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: nil)}
            .bind(to: destinationAmountInput)
            .disposed(by: disposeBag)
        
        // TODO: Reverse: estimated amount to input amount
        
        // minimum receive
        Observable.combineLatest(
            currentPool.distinctUntilChanged(),
            sourceAmountInput.distinctUntilChanged(),
            slippage.distinctUntilChanged()
        )
            .map {[weak self] _ in self?.calculateMinimumReceiveAmount()}
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
            .map {_ in self.verifyError()}
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
    
    @objc func showSwapSceneAndSwap() {
        navigationSubject.onNext(.processTransaction)
        swap()
    }
    
    func destinationWalletDidSelect(_ wallet: Wallet) {
        // check if wallet has required data
        if wallet.pubkey != nil && wallet.token.decimals != nil {
            destinationWallet.accept(wallet)
            return
        }
        
        // fetch needed data
        navigationSubject.onNext(.loading(true))
        if let mint = try? SolanaSDK.PublicKey(string: wallet.mintAddress) {
            solanaSDK.getMintData(mintAddress: mint)
                .map {Int($0.decimals)}
                .subscribe(onSuccess: {[weak self] decimals in
                    self?.navigationSubject.onNext(.loading(false))
                    var wallet = wallet
                    wallet.token.decimals = decimals
                    self?.destinationWallet.accept(wallet)
                }, onFailure: {[weak self] error in
                    self?.navigationSubject.onNext(.loading(false))
                    self?.errorSubject.accept(error.readableDescription)
                })
                .disposed(by: disposeBag)
        } else {
            navigationSubject.onNext(.loading(false))
            errorSubject.accept(L10n.tokenSMintAddressIsNotValid)
        }
        
    }
    
    private func swap() {
        guard let sourceWallet = sourceWallet.value,
              let sourcePubkey = try? SolanaSDK.PublicKey(string: sourceWallet.pubkey ?? ""),
              let sourceMint = try? SolanaSDK.PublicKey(string: sourceWallet.mintAddress),
              let destinationWallet = destinationWallet.value,
              let destinationMint = try? SolanaSDK.PublicKey(string: destinationWallet.mintAddress),
              
              let sourceDecimals = sourceWallet.decimals,
              let amountDouble = sourceAmountInput.value.double
        else {
            return
        }
        
        let lamports = amountDouble.toLamport(decimals: sourceDecimals)
        let destinationPubkey = try? SolanaSDK.PublicKey(string: destinationWallet.pubkey ?? "")
        
        var transaction = Transaction(
            type: .send,
            amount: +(self.destinationAmountInput.value.double ?? 0),
            symbol: destinationWallet.symbol,
            status: .processing
        )
        
        self.processTransactionViewModel.transactionInfo.accept(
            TransactionInfo(transaction: transaction)
        )
        
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
                transaction.signatureInfo = .init(signature: signature)
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction)
                )
                self.transactionManager.process(transaction)
                
                let transaction2 = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: -amountDouble,
                    symbol: sourceWallet.symbol,
                    status: .processing
                )
                self.transactionManager.process(transaction2)
            }, onFailure: {error in
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction, error: error)
                )
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    
    /// Verify current context
    /// - Returns: Error string, nil if no error appear
    private func verifyError() -> String? {
        // get variables
        let sourceAmountInput = self.sourceAmountInput.value
        let sourceWallet = self.sourceWallet.value
        let destinationWallet = self.destinationWallet.value
        let pool = self.currentPool.value
        let slippage = self.slippage.value
        
        // Verify amount
        if let input = sourceAmountInput.double {
            // amount is empty
            if input <= 0, pool != nil {
                return L10n.amountIsNotValid
            }
            
            // insufficient funds
            if input.rounded(decimals: sourceWallet?.decimals) > sourceWallet?.amount?.rounded(decimals: sourceWallet?.decimals)
            {
                return L10n.insufficientFunds
            }
        }
        
        // Verify slippage
        if !isSlippageValid(slippage: slippage) {
            return L10n.slippageIsnTValid
        }
        
        // Verify pool
        if pool == nil {
            // if there are pools, but there is no pool for current pairs
            if let pools = self.pools.value,
               !pools.isEmpty
            {
                if let sourceWallet = sourceWallet,
                   let destinationWallet = destinationWallet
                {
                    if sourceWallet.symbol == destinationWallet.symbol {
                        return L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.symbol)
                    } else {
                        return L10n.swappingFromToIsCurrentlyUnsupported(sourceWallet.symbol, destinationWallet.symbol)
                    }
                }
            }
            // if there is no pools at all
            else {
                return L10n.swappingIsCurrentlyUnavailable
            }
        }
        
        return nil
    }
}

private extension SwapTokenViewModel {
    // MARK: - Calculator
    private var sourceDecimals: Int? {
        sourceWallet.value?.decimals
    }
    
    private var destinationDecimals: Int? {
        destinationWallet.value?.decimals
    }
    
    private var slippageValue: Double {
        slippage.value
    }
    
    /// Calculate input amount for receving expected amount
    /// - Parameter expectedAmount: expected amount of receiver
    /// - Returns: input amount for receiving expected amount
    func calculateInputAmount(forExpectedAmount expectedAmount: Double?) -> Double? {
        guard let expectedAmount = expectedAmount,
              expectedAmount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let inputAmountLamports = currentPool.value?.inputAmount(forEstimatedAmount: expectedAmount.toLamport(decimals: destinationDecimals))
        else {return nil}
        return inputAmountLamports.convertToBalance(decimals: sourceDecimals)
    }
    
    /// Calculate estimated amount for an input amount
    /// - Returns: estimated amount from input amount
    func calculateEstimatedAmount(forInputAmount inputAmount: Double?) -> Double? {
        guard let inputAmount = inputAmount,
              inputAmount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let estimatedAmountLamports = currentPool.value?.estimatedAmount(forInputAmount: inputAmount.toLamport(decimals: sourceDecimals))
        else {return nil}
        return estimatedAmountLamports.convertToBalance(decimals: destinationDecimals)
    }
    
    /// Calculate minimum receive amount from input amount
    /// - Returns: minimum receive amount
    func calculateMinimumReceiveAmount() -> Double? {
        guard let amount = sourceAmountInput.value?.double,
              amount > 0,
              let sourceDecimals = self.sourceWallet.value?.decimals,
              let destinationDecimals = self.destinationWallet.value?.decimals,
              let estimatedAmountLamports = currentPool.value?.estimatedAmount(forInputAmount: amount.toLamport(decimals: sourceDecimals)),
              let lamports = currentPool.value?.minimumReceiveAmount(estimatedAmount: estimatedAmountLamports, slippage: slippage.value)
        else {return nil}
        return lamports.convertToBalance(decimals: destinationDecimals)
    }
}
