//
//  SwapToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import LazySubject

extension SwapToken {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            let sourceWallet = PublishRelay<Wallet?>()
            let destinationWallet = PublishRelay<Wallet?>()
            let amount = PublishRelay<String?>()
            let estimatedAmount = PublishRelay<String?>()
            let slippage = PublishRelay<Double>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let pool: Driver<SolanaSDK.Pool?>
            let isLoading: Driver<Bool>
            let error: Driver<String?>
            let isValid: Driver<Bool>
            let sourceWallet: Driver<Wallet?>
            let availableAmount: Driver<Double?>
            let destinationWallet: Driver<Wallet?>
            let amount: Driver<Double?>
            let estimatedAmount: Driver<Double?>
            let liquidityProviderFee: Driver<Double?>
            let feeInLamports: Driver<SolanaSDK.Lamports?>
            let slippage: Driver<Double>
            let minimumReceiveAmount: Driver<Double?>
            let useAllBalanceDidTap: Driver<Double?>
            let isExchageRateReversed: Driver<Bool>
        }
        
        // MARK: - Dependencies
        private let solWallet: Wallet?
        private let apiClient: SwapTokenAPIClient
        private let authenticationHandler: AuthenticationHandler
        let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        private var isSelectingSourceWallet = true
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private lazy var poolsSubject = LazySubject<[SolanaSDK.Pool]>(request: apiClient.getSwapPools())
        private lazy var lamportsPerSignatureSubject = LazySubject<SolanaSDK.Lamports>(request: apiClient.getLamportsPerSignature())
        private lazy var creatingAccountFeeSubject = LazySubject<SolanaSDK.Lamports>(request: apiClient.getCreatingTokenAccountFee())
        private let isLoadingSubject = PublishRelay<Bool>()
        private let errorSubject = PublishRelay<String?>()
        private let isValidSubject = BehaviorRelay<Bool>(value: false)
        private let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let availableAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let currentPoolSubject = BehaviorRelay<SolanaSDK.Pool?>(value: nil)
        private let compensationPoolSubject = BehaviorRelay<SolanaSDK.Pool?>(value: nil)
        private let amountSubject = BehaviorRelay<Double?>(value: nil)
        private let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let liquidityProviderFeeSubject = BehaviorRelay<Double?>(value: nil)
        private let slippageSubject = BehaviorRelay<Double>(value: Defaults.slippage)
        private let minimumReceiveAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let useAllBalanceDidTapSubject = PublishRelay<Double?>()
        private let isExchageRateReversedSubject = BehaviorRelay<Bool>(value: false)
        private let feeInLamportsSubject = BehaviorRelay<SolanaSDK.Lamports?>(value: nil)
        
        // MARK: - Initializer
        init(
            solWallet: Wallet?,
            apiClient: SwapTokenAPIClient,
            authenticationHandler: AuthenticationHandler,
            analyticsManager: AnalyticsManagerType
        ) {
            self.solWallet = solWallet
            self.apiClient = apiClient
            self.authenticationHandler = authenticationHandler
            self.analyticsManager = analyticsManager
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                pool: currentPoolSubject
                    .asDriver(),
                isLoading: isLoadingSubject
                    .asDriver(onErrorJustReturn: false),
                error: errorSubject
                    .asDriver(onErrorJustReturn: nil),
                isValid: isValidSubject
                    .asDriver(),
                sourceWallet: sourceWalletSubject
                    .asDriver(),
                availableAmount: availableAmountSubject
                    .asDriver(),
                destinationWallet: destinationWalletSubject
                    .asDriver(),
                amount: amountSubject
                    .asDriver(),
                estimatedAmount: estimatedAmountSubject
                    .asDriver(),
                liquidityProviderFee: liquidityProviderFeeSubject
                    .asDriver(),
                feeInLamports: feeInLamportsSubject
                    .asDriver(),
                slippage: slippageSubject
                    .asDriver(),
                minimumReceiveAmount: minimumReceiveAmountSubject
                    .asDriver(),
                useAllBalanceDidTap: useAllBalanceDidTapSubject
                    .asDriver(onErrorJustReturn: nil),
                isExchageRateReversed: isExchageRateReversedSubject
                    .asDriver()
            )
            
            bind()
            reload()
        }
        
        /// Bind subjects
        private func bind() {
            bindInputIntoSubjects()
            bindSubjectsIntoSubjects()
        }
        
        private func bindInputIntoSubjects() {
            // source wallet
            input.sourceWallet
                .bind(to: sourceWalletSubject)
                .disposed(by: disposeBag)
            
            // destination wallet
            input.destinationWallet
                .bind(to: destinationWalletSubject)
                .disposed(by: disposeBag)
            
            // amount
            input.amount
                .map {$0?.double}
                .bind(to: amountSubject)
                .disposed(by: disposeBag)
            
            // estimated amount
            input.estimatedAmount
                .map {$0?.double}
                .bind(to: estimatedAmountSubject)
                .disposed(by: disposeBag)
            
            // slippage
            input.slippage
                .do(onNext: {[weak self] slippage in
                    self?.analyticsManager.log(event: .swapSlippageKeydown(slippage: slippage))
                })
                .bind(to: slippageSubject)
                .disposed(by: disposeBag)
        }
        
        private func bindSubjectsIntoSubjects() {
            let combinedState = Observable.combineLatest([
                poolsSubject.observable,
                lamportsPerSignatureSubject.observable,
                creatingAccountFeeSubject.observable
            ])
                .map {$0.combinedState}
            
            // pools
            combinedState
                .subscribe(onNext: {[weak self] state in
                    switch state {
                    case .initializing, .loading:
                        self?.isLoadingSubject.accept(true)
                        self?.errorSubject.accept(nil)
                    case .loaded:
                        self?.isLoadingSubject.accept(false)
                        self?.errorSubject.accept(nil)
                    case .error:
                        self?.isLoadingSubject.accept(false)
                        self?.errorSubject.accept(L10n.swappingIsCurrentlyUnavailable)
                    }
                })
                .disposed(by: disposeBag)
            
            // pools loaded
            let dataLoaded = combinedState
                .filter {$0 == .loaded}
                .map {[weak self] _ in self?.poolsSubject.value}
            
            // current pool, compensation pool
            Observable.combineLatest(
                dataLoaded,
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
                .flatMap { [weak self] _ -> Single<(pool: SolanaSDK.Pool?, compensationPool: SolanaSDK.Pool?)> in
                    guard let self = self else {return .just((pool: nil, compensationPool: nil))}
                    self.isLoadingSubject.accept(true)
                    return self.loadPools()
                }
                .asDriver(onErrorJustReturn: (pool: nil, compensationPool: nil))
                .drive(onNext: {[weak self] pools in
                    guard let self = self else {return}
                    self.isLoadingSubject.accept(false)
                    self.currentPoolSubject.accept(pools.pool)
                    self.compensationPoolSubject.accept(pools.compensationPool)
                })
                .disposed(by: disposeBag)
            
            // estimated amount from input amount
            Observable.combineLatest(
                currentPoolSubject.distinctUntilChanged(),
                input.amount.map {$0?.double}
            )
                .map {[weak self] in self?.calculateEstimatedAmount(forInputAmount: $1)}
                .bind(to: estimatedAmountSubject)
                .disposed(by: disposeBag)
            
            // input amount from estimated amount
            Observable.combineLatest(
                currentPoolSubject.distinctUntilChanged(),
                input.estimatedAmount.map {$0?.double}
            )
                .map {[weak self] in self?.calculateInputAmount(forExpectedAmount: $1)}
                .bind(to: amountSubject)
                .disposed(by: disposeBag)
            
            // fee
            Observable.combineLatest(
                currentPoolSubject.distinctUntilChanged(),
                amountSubject.distinctUntilChanged()
            )
                .map {calculateFee(forInputAmount: $1, in: $0)}
                .bind(to: liquidityProviderFeeSubject)
                .disposed(by: disposeBag)
            
            // fee in lamports
            Observable.combineLatest(
                compensationPoolSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                lamportsPerSignatureSubject.dataObservable,
                creatingAccountFeeSubject.dataObservable
            )
                .map {compensationPool, sourceWallet, destinationWallet, lamportsPerSignature, creatingAccountFee -> SolanaSDK.Lamports? in
                    var fee = calculateFeeInLamport(sourceWallet: sourceWallet, destinationWallet: destinationWallet, lamportsPerSignature: lamportsPerSignature, creatingAccountFee: creatingAccountFee)
                    
                    // if fee relayer is available
                    if let pool = compensationPool
                    {
                        if let currentFee = fee {
                            fee = pool.inputAmount(forMinimumReceiveAmount: currentFee, slippage: SolanaSDK.Pool.feeCompensationPoolDefaultSlippage, roundRules: .up, includeFees: true)
                        } else {
                            fee = 0
                        }
                    }
                    
                    return fee
                }
                .bind(to: feeInLamportsSubject)
                .disposed(by: disposeBag)
            
            // available amount
            Observable.combineLatest(
                sourceWalletSubject,
                destinationWalletSubject,
                feeInLamportsSubject
            )
                .map {sourceWallet, destinationWallet, feeInLamports -> Double? in
                    calculateAvailableAmount(sourceWallet: sourceWallet, destinationWallet: destinationWallet, feeInLamports: feeInLamports)
                }
                .bind(to: availableAmountSubject)
                .disposed(by: disposeBag)
            
            // minimum receive amount
            Observable.combineLatest(
                currentPoolSubject.distinctUntilChanged(),
                amountSubject.distinctUntilChanged(),
                slippageSubject.distinctUntilChanged()
            )
                .map {[weak self] _ in self?.calculateMinimumReceiveAmount()}
                .bind(to: minimumReceiveAmountSubject)
                .disposed(by: disposeBag)
                
            // error subject
            Observable.combineLatest(
                poolsSubject.observable,
                currentPoolSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                amountSubject,
                slippageSubject
            )
                .map {_ in self.verifyError()}
                .bind(to: errorSubject)
                .disposed(by: disposeBag)
            
            // isValid subject
            Observable.combineLatest(
                currentPoolSubject,
                amountSubject,
                errorSubject.map {$0 == nil}
            )
                .map {$0 != nil && $1 > 0 && $2}
                .bind(to: isValidSubject)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func reload() {
            poolsSubject.reload()
            lamportsPerSignatureSubject.reload()
            creatingAccountFeeSubject.reload()
        }
        
        @objc func useAllBalance() {
            let amount = availableAmountSubject.value
            
            if let amount = amount {
                analyticsManager.log(event: .swapAvailableClick(sum: amount))
            }
            
            input.amount.accept(amount?.toString(maximumFractionDigits: 9, groupingSeparator: nil))
            useAllBalanceDidTapSubject.accept(amount)
        }
        
        @objc func chooseSourceWallet() {
            isSelectingSourceWallet = true
            navigationSubject.accept(.chooseSourceWallet)
        }
        
        @objc func chooseDestinationWallet() {
            isSelectingSourceWallet = false
            isLoadingSubject.accept(true)
            getValidDestinationWalletMints()
                .subscribe(onSuccess: {[weak self] validMints in
                    self?.isLoadingSubject.accept(false)
                    self?.navigationSubject.accept(.chooseDestinationWallet(validMints: validMints, excludedSourceWalletPubkey: self?.sourceWalletSubject.value?.pubkey))
                }, onFailure: { [weak self] _ in
                    self?.isLoadingSubject.accept(false)
                })
                .disposed(by: disposeBag)
        }
        
        @objc func swapSourceAndDestination() {
            analyticsManager.log(event: .swapReverseClick)
            
            let tempWallet = sourceWalletSubject.value
            sourceWalletSubject.accept(destinationWalletSubject.value)
            destinationWalletSubject.accept(tempWallet)
        }
        
        @objc func reverseExchangeRate() {
            isExchageRateReversedSubject.accept(!isExchageRateReversedSubject.value)
        }
        
        @objc func showSettings() {
            analyticsManager.log(event: .swapSettingsClick)
            navigationSubject.accept(.settings)
        }
        
        @objc func chooseSlippage() {
            analyticsManager.log(event: .swapSlippageClick)
            navigationSubject.accept(.chooseSlippage)
        }
        
        @objc func authenticateAndSwap() {
            authenticationHandler.authenticate(
                presentationStyle:
                    .init(
                        isRequired: false,
                        isFullScreen: false,
                        completion: { [weak self] in
                            self?.swap()
                        }
                    )
            )
        }
        
        // MARK: - Helpers
        private func loadPools() -> Single<(pool: SolanaSDK.Pool?, compensationPool: SolanaSDK.Pool?)> {
            guard let pools = poolsSubject.value,
                  let sourceWallet = sourceWalletSubject.value,
                  let destinationWallet = destinationWalletSubject.value
            else {return .just((pool: nil, compensationPool: nil))}
            
            let swapPools = pools.getMatchedPools(
                sourceMint: sourceWallet.mintAddress,
                destinationMint: destinationWallet.mintAddress
            )
            
            let compensationPools = pools.getMatchedPools(
                sourceMint: sourceWallet.mintAddress,
                destinationMint: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
            )
            
            let getPoolRequest: Single<SolanaSDK.Pool?>
            if let pool = swapPools.first(where: {$0.isValid}) {
                getPoolRequest = .just(pool)
            } else {
                getPoolRequest = Single.zip(swapPools.map {apiClient.getPoolWithTokenBalances(pool: $0)})
                    .map {$0.first(where: {$0.isValid})}
            }
            
            let getCompensationPoolRequest: Single<SolanaSDK.Pool?>
            if !SwapToken.isFeeRelayerEnabled(source: sourceWallet, destination: destinationWallet) {
                getCompensationPoolRequest = .just(nil)
            } else if let pool = compensationPools.first(where: {$0.isValid}) {
                getCompensationPoolRequest = .just(pool)
            } else {
                getCompensationPoolRequest = Single.zip(compensationPools.map {apiClient.getPoolWithTokenBalances(pool: $0)})
                    .map {$0.first(where: {$0.isValid})}
            }
            
            return Single.zip(getPoolRequest, getCompensationPoolRequest)
                .map {(pool: $0, compensationPool: $1)}
        }
        
        /// Verify current context
        /// - Returns: Error string, nil if no error appear
        private func verifyError() -> String? {
            // get variables
            let sourceAmountInput = amountSubject.value
            let sourceWallet = sourceWalletSubject.value
            let availableAmount = availableAmountSubject.value
            let destinationWallet = destinationWalletSubject.value
            let pool = currentPoolSubject.value
            let slippage = slippageSubject.value
            
            // Verify amount
            if let input = sourceAmountInput {
                // amount is empty
                if input <= 0, pool != nil {
                    return L10n.amountIsNotValid
                }
                
                // insufficient funds
                if input.rounded(decimals: sourceDecimals) > availableAmount?.rounded(decimals: sourceDecimals)
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
                if let pools = self.poolsSubject.value,
                   !pools.isEmpty
                {
                    if let sourceWallet = sourceWallet,
                       let destinationWallet = destinationWallet
                    {
                        if sourceWallet.token.symbol == destinationWallet.token.symbol {
                            return L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.token.symbol)
                        } else {
                            return L10n.swappingFromToIsCurrentlyUnsupported(sourceWallet.token.symbol, destinationWallet.token.symbol)
                        }
                    }
                }
                // if there is no pools at all
                else {
                    return L10n.swappingIsCurrentlyUnavailable
                }
            }
            
            // Verify feeInLamports
            // fee relayer
            if SwapToken.isFeeRelayerEnabled(source: sourceWallet, destination: destinationWallet)
            {
                if (sourceWallet?.lamports ?? 0) < (feeInLamportsSubject.value ?? 0)
                {
                    return L10n.notEnoughToPayNetworkFee(sourceWallet!.token.symbol)
                }
            }
            // normal transactions
            else if let solWallet = solWallet,
               (solWallet.lamports ?? 0) < (feeInLamportsSubject.value ?? 0)
            {
                return L10n.notEnoughToPayNetworkFee("SOL")
            }
            
            return nil
        }
        
        func isSlippageValid(slippage: Double) -> Bool {
            slippage <= .maxSlippage && slippage > 0
        }
        
        private func getValidDestinationWalletMints() -> Single<Set<String>> {
            // get source wallet mint, available mint
            guard let sourceWalletMint = sourceWalletSubject.value?.mintAddress,
                  let availablePools = poolsSubject.value?.getPools(mintA: sourceWalletMint),
                  availablePools.count > 0
            else {
                return .just([])
            }
            
            // retrieve balances and filter out empty pools
            let getTokenBalancesRequests: [Single<SolanaSDK.Pool?>] = availablePools.map {
                apiClient.getPoolWithTokenBalances(pool: $0)
                    .map(Optional.init)
                    .catchAndReturn(nil)
            }
            return Single.zip(getTokenBalancesRequests)
                .do(onSuccess: { [weak self] newPools in
                    // update pools
                    guard let self = self, var pools = self.poolsSubject.value else {return}
                    for newPool in newPools {
                        if let newPool = newPool, let index = pools.firstIndex(where: {$0.address == newPool.address}
                        ) {
                            pools[index] = newPool
                            
                            // remove empty pool
                            if newPool.tokenABalance?.amountInUInt64 == 0 || newPool.tokenABalance?.amountInUInt64 == 0
                            {
                                pools.removeAll(where: {$0.address == newPool.address})
                            }
                        }
                    }
                    self.poolsSubject.updateValue(pools)
                })
                .map { $0.filter {$0?.isValid == true} }
                .map { $0.map {$0!.swapData.mintB.base58EncodedString} }
                .map { Set($0) }
        }
        
        private func swap() {
            guard let sourceWallet = sourceWalletSubject.value,
                  let sourcePubkey = try? SolanaSDK.PublicKey(string: sourceWallet.pubkey ?? ""),
                  let sourceMint = try? SolanaSDK.PublicKey(string: sourceWallet.mintAddress),
                  let destinationWallet = destinationWalletSubject.value,
                  let destinationMint = try? SolanaSDK.PublicKey(string: destinationWallet.mintAddress),
                  let amountDouble = amountSubject.value
            else {
                return
            }
            
            let sourceDecimals = sourceWallet.token.decimals
            let lamports = amountDouble.toLamport(decimals: sourceDecimals)
            let destinationPubkey = try? SolanaSDK.PublicKey(string: destinationWallet.pubkey ?? "")
            
            let request = apiClient.swap(
                account: nil,
                pool: currentPoolSubject.value,
                source: sourcePubkey,
                sourceMint: sourceMint,
                destination: destinationPubkey,
                destinationMint: destinationMint,
                slippage: slippageSubject.value,
                amount: lamports,
                isSimulation: false
            )
                .map {$0 as ProcessTransactionResponseType}
            
            // calculate amount
            let inputAmount = amountDouble
            let estimatedAmount = estimatedAmountSubject.value ?? 0
            
            // log
            analyticsManager.log(event: .swapSwapClick(tokenA: sourceWallet.token.symbol, tokenB: destinationWallet.token.symbol, sumA: inputAmount, sumB: estimatedAmount))
            
            // show processing scene
            navigationSubject.accept(
                .processTransaction(
                    request: request,
                    transactionType: .swap(
                        from: sourceWallet,
                        to: destinationWallet,
                        inputAmount: lamports,
                        estimatedAmount: estimatedAmount.toLamport(decimals: destinationWallet.token.decimals),
                        fee: feeInLamportsSubject.value ?? 0
                    )
                )
            )
        }
    }
}

extension SwapToken.ViewModel: WalletDidSelectHandler {
    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
            input.sourceWallet.accept(wallet)
        } else {
            analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
            input.destinationWallet.accept(wallet)
        }
    }
}

private extension SwapToken.ViewModel {
    // MARK: - Calculator
    private var sourceDecimals: UInt8? {
        sourceWalletSubject.value?.token.decimals
    }
    
    private var destinationDecimals: UInt8? {
        destinationWalletSubject.value?.token.decimals
    }
    
    /// Calculate input amount for receving expected amount
    /// - Parameter expectedAmount: expected amount of receiver
    /// - Returns: input amount for receiving expected amount
    func calculateInputAmount(forExpectedAmount expectedAmount: Double?) -> Double? {
        guard let expectedAmount = expectedAmount,
              expectedAmount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let inputAmountLamports = currentPoolSubject.value?.inputAmount(forEstimatedAmount: expectedAmount.toLamport(decimals: destinationDecimals), includeFees: true)
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
              let estimatedAmountLamports = currentPoolSubject.value?.estimatedAmount(forInputAmount: inputAmount.toLamport(decimals: sourceDecimals), includeFees: true)
        else {return nil}
        return estimatedAmountLamports.convertToBalance(decimals: destinationDecimals)
    }
    
    /// Calculate minimum receive amount from input amount
    /// - Returns: minimum receive amount
    func calculateMinimumReceiveAmount() -> Double? {
        guard let amount = amountSubject.value,
              amount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let lamports = currentPoolSubject.value?.minimumReceiveAmount(fromInputAmount: amount.toLamport(decimals: sourceDecimals), slippage: slippageSubject.value, includesFees: true)
        else {return nil}
        return lamports.convertToBalance(decimals: destinationDecimals)
    }
}

private func calculateFee(forInputAmount inputAmount: Double?, in pool: SolanaSDK.Pool?) -> Double? {
    guard let inputAmount = inputAmount, let pool = pool else {return nil}
    return pool.fee(forInputAmount: inputAmount)
}

private func calculateFeeInLamport(sourceWallet: Wallet?, destinationWallet: Wallet?, lamportsPerSignature: SolanaSDK.Lamports?, creatingAccountFee: SolanaSDK.Lamports?) -> SolanaSDK.Lamports?
{
    let creatingAccountFee = creatingAccountFee ?? 0
    guard let lPS = lamportsPerSignature else {return nil}
    
    // default fee
    var feeInLamports = lPS * 2
    
    guard let sourceWallet = sourceWallet
    else {return feeInLamports}
    
    // if token is native, a fee for creating wrapped SOL is needed
    if sourceWallet.token.isNative {
        feeInLamports += lPS
        feeInLamports += creatingAccountFee
    }
    
    // if destination wallet is selected
    if let destinationWallet = destinationWallet {
        // if destination wallet is a wrapped sol, a fee for creating it is needed
        if destinationWallet.token.address == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
        {
            feeInLamports += lPS
            feeInLamports += creatingAccountFee
        }
        
        // if destination wallet is not a wrapped sol and has not yet created, a fee for creating it is needed
        else if destinationWallet.pubkey == nil {
            feeInLamports += lPS
            feeInLamports += creatingAccountFee
        }
    }
    
    // fee relayer
    if SwapToken.isFeeRelayerEnabled(source: sourceWallet, destination: destinationWallet)
    {
        feeInLamports += lPS // fee for creating a SOL account
    }
    
    return feeInLamports
}

private func calculateAvailableAmount(sourceWallet wallet: Wallet?, destinationWallet: Wallet?, feeInLamports: SolanaSDK.Lamports?) -> Double?
{
    guard let sourceWallet = wallet,
          let feeInLamports = feeInLamports
    else {return wallet?.amount}
    
    // if token is not nativeSolana and are not using fee relayer
    if !sourceWallet.token.isNative && !SwapToken.isFeeRelayerEnabled(source: sourceWallet, destination: destinationWallet)
    {return sourceWallet.amount}
    
    let availableAmount = (sourceWallet.amount ?? 0) - feeInLamports.convertToBalance(decimals: sourceWallet.token.decimals)
    return availableAmount > 0 ? availableAmount: 0
}
