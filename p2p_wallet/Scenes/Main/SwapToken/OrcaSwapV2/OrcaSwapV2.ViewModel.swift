//
//  OrcaSwapV2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol OrcaSwapV2ViewModelType: WalletDidSelectHandler, SwapTokenSettingsViewModelType, SwapTokenSwapFeesViewModelType {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {get}
    var loadingStateDriver: Driver<LoadableState> {get}
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {get}
    var inputAmountDriver: Driver<Double?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    var feesDriver: Driver<Loadable<[PayingFee]>> {get}
    var availableAmountDriver: Driver<Double?> {get}
    var slippageDriver: Driver<Double> {get}
    var minimumReceiveAmountDriver: Driver<Double?> {get}
    var exchangeRateDriver: Driver<Double?> {get}
    var payingTokenDriver: Driver<PayingToken> {get}
    var errorDriver: Driver<OrcaSwapV2.VerificationError?> {get}
    
    func reload()
    func log(_ event: AnalyticsEvent)
    func navigate(to scene: OrcaSwapV2.NavigatableScene)
    func chooseSourceWallet()
    func chooseDestinationWallet()
    func swapSourceAndDestination()
    func useAllBalance()
    func enterInputAmount(_ amount: Double?)
    func enterEstimatedAmount(_ amount: Double?)
    func changeSlippage(to slippage: Double)
    func reverseExchangeRate()
    func changePayingToken(to payingToken: PayingToken)
    
    func authenticateAndSwap()
}

extension OrcaSwapV2 {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        private let orcaSwap: OrcaSwapType
        private let walletsRepository: WalletsRepository
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isSelectingSourceWallet = false // indicate if selecting source wallet or destination wallet
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        private let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let tradablePoolsPairsSubject = LoadableRelay<[OrcaSwap.PoolsPair]>(request: .just([]))
        private let bestPoolsPairSubject = BehaviorRelay<OrcaSwap.PoolsPair?>(value: nil)
        private let inputAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let feesSubject = LoadableRelay<[PayingFee]>(request: .just([.init(type: .transactionFee, lamports: 0, token: .nativeSolana)])) // FIXME
        private let slippageSubject = BehaviorRelay<Double>(value: Defaults.slippage)
        private let isExchangeRateReversedSubject = BehaviorRelay<Bool>(value: false)
        private let payingTokenSubject = BehaviorRelay<PayingToken>(value: Defaults.payingToken)
        private let errorSubject = BehaviorRelay<VerificationError?>(value: nil)
        
        // MARK: - Initializer
        init(
            orcaSwap: OrcaSwapType,
            walletsRepository: WalletsRepository,
            initialWallet: Wallet?
        ) {
            self.orcaSwap = orcaSwap
            self.walletsRepository = walletsRepository
            
            bind(initialWallet: initialWallet)
        }
        
        func bind(initialWallet: Wallet?) {
            // wait until loaded and choose initial wallet
            if let initialWallet = initialWallet {
                loadingStateSubject
                    .take(until: {$0 == .loaded})
                    .take(1)
                    .subscribe(onNext: {[weak self] _ in
                        self?.sourceWalletSubject.accept(initialWallet)
                    })
                    .disposed(by: disposeBag)
            }
            
            // get tradable pools pair for each token pair
            Observable.combineLatest(
                sourceWalletSubject,
                destinationWalletSubject
            )
                .subscribe(onNext: {[weak self] sourceWallet, destinationWallet in
                    guard let self = self,
                          let sourceWallet = sourceWallet,
                          let destinationWallet = destinationWallet
                    else {
                        self?.tradablePoolsPairsSubject.request = .just([])
                        self?.tradablePoolsPairsSubject.reload()
                        self?.fixPayingToken()
                        return
                    }
                    
                    self.tradablePoolsPairsSubject.request = self.orcaSwap.getTradablePoolsPairs(
                        fromMint: sourceWallet.token.address,
                        toMint: destinationWallet.token.address
                    )
                    self.tradablePoolsPairsSubject.reload()
                    self.fixPayingToken()
                })
                .disposed(by: disposeBag)
            
            // FIXME: - fill input amount and estimated amount after loaded
            tradablePoolsPairsSubject.stateObservable
                .distinctUntilChanged()
                .filter {$0 == .loaded}
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else {return}
                    if let inputAmount = self.inputAmountSubject.value {
                        self.enterInputAmount(inputAmount)
                    } else if let estimatedAmount = self.estimatedAmountSubject.value {
                        self.enterEstimatedAmount(estimatedAmount)
                    }
                })
                .disposed(by: disposeBag)
            
            // TODO: - Calculate fees
            
            // Error
            Observable.combineLatest(
                loadingStateSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                tradablePoolsPairsSubject.stateObservable,
                bestPoolsPairSubject,
                feesSubject.valueObservable,
                slippageSubject,
                payingTokenSubject
            )
                .map {[weak self] _ in self?.verify() }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)
        }
        
        func authenticateAndSwap() {
            fatalError("Implementing")
        }
    }
}

extension OrcaSwapV2.ViewModel: OrcaSwapV2ViewModelType {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var loadingStateDriver: Driver<LoadableState> {
        loadingStateSubject.asDriver()
    }
    
    var sourceWalletDriver: Driver<Wallet?> {
        sourceWalletSubject.asDriver()
    }
    
    var destinationWalletDriver: Driver<Wallet?> {
        destinationWalletSubject.asDriver()
    }
    
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {
        tradablePoolsPairsSubject.asDriver()
            .map { value, state, reloadAction in
                (value?.isEmpty == false, state, reloadAction)
            }
    }
    
    var inputAmountDriver: Driver<Double?> {
        inputAmountSubject.asDriver()
    }
    
    var estimatedAmountDriver: Driver<Double?> {
        estimatedAmountSubject.asDriver()
    }
    
    var feesDriver: Driver<Loadable<[PayingFee]>> {
        feesSubject.asDriver()
    }
    
    var availableAmountDriver: Driver<Double?> {
        Driver.combineLatest(
            sourceWalletDriver,
            destinationWalletDriver,
            feesDriver
        )
            .map {[weak self] _ in self?.calculateAvailableAmount()}
    }
    
    var slippageDriver: Driver<Double> {
        slippageSubject.asDriver()
    }
    
    var minimumReceiveAmountDriver: Driver<Double?> {
        bestPoolsPairSubject
            .withLatestFrom(
                Observable.combineLatest(
                    inputAmountSubject,
                    slippageSubject,
                    sourceWalletSubject,
                    destinationWalletSubject
                )
            ) { ($0, $1.0, $1.1, $1.2, $1.3) }
            .map { poolsPair, inputAmount, slippage, sourceWallet, destinationWallet in
                guard let poolsPair = poolsPair,
                      let sourceDecimals = sourceWallet?.token.decimals,
                      let inputAmount = inputAmount?.toLamport(decimals: sourceDecimals),
                      let destinationDecimals = destinationWallet?.token.decimals
                else {return nil}
                return poolsPair.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)?.convertToBalance(decimals: destinationDecimals)
            }
            .asDriver(onErrorJustReturn: nil)
    }
    
    var exchangeRateDriver: Driver<Double?> {
        Observable.combineLatest(
            inputAmountSubject,
            estimatedAmountSubject
        )
            .withLatestFrom(isExchangeRateReversedSubject.asObservable()) {($0.0, $0.1, $1)}
            .map { inputAmount, estimatedAmount, isReversed in
                guard let inputAmount = inputAmount,
                      let estimatedAmount = estimatedAmount,
                      inputAmount > 0,
                      estimatedAmount > 0
                else {return nil}
                return isReversed ? inputAmount / estimatedAmount: estimatedAmount / inputAmount
            }
            .asDriver(onErrorJustReturn: nil)
    }
    
    var payingTokenDriver: Driver<PayingToken> {
        payingTokenSubject.asDriver()
    }
    
    var errorDriver: Driver<OrcaSwapV2.VerificationError?> {
        errorSubject.asDriver()
    }
    
    // MARK: - Actions
    func reload() {
        loadingStateSubject.accept(.loading)
        orcaSwap.load()
            .subscribe(onCompleted: { [weak self] in
                self?.loadingStateSubject.accept(.loaded)
            }, onError: {error in
                self.loadingStateSubject.accept(.error(error.readableDescription))
            })
            .disposed(by: disposeBag)
    }
    
    func log(_ event: AnalyticsEvent) {
        analyticsManager.log(event: event)
    }
    
    func navigate(to scene: OrcaSwapV2.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func chooseSourceWallet() {
        isSelectingSourceWallet = true
        navigationSubject.accept(.chooseSourceWallet)
    }
    
    func chooseDestinationWallet() {
        guard let sourceWallet = sourceWalletSubject.value,
              let destinationMints = try? orcaSwap.findPosibleDestinationMints(fromMint: sourceWallet.token.address)
        else {return}
        isSelectingSourceWallet = false
        navigationSubject.accept(.chooseDestinationWallet(validMints: Set(destinationMints), excludedSourceWalletPubkey: sourceWallet.pubkey))
    }
    
    func swapSourceAndDestination() {
        let source = sourceWalletSubject.value
        sourceWalletSubject.accept(destinationWalletSubject.value)
        destinationWalletSubject.accept(source)
    }
    
    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
            sourceWalletSubject.accept(wallet)
        } else {
            analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
            destinationWalletSubject.accept(wallet)
        }
    }
    
    func useAllBalance() {
        // TODO: - useAllBalance
//        // calculate available balance
//
//        // input
//        enterInputAmount(availableBalance)
    }
    
    func enterInputAmount(_ amount: Double?) {
        inputAmountSubject.accept(amount)
        
        // calculate estimated amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs),
           let bestEstimatedAmount = bestPoolsPair.getOutputAmount(fromInputAmount: inputAmount)
        {
            bestPoolsPairSubject.accept(bestPoolsPair)
            estimatedAmountSubject.accept(bestEstimatedAmount.convertToBalance(decimals: destinationDecimals))
        }
    }
    
    func enterEstimatedAmount(_ amount: Double?) {
        estimatedAmountSubject.accept(amount)
        
        // calculate input amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let estimatedAmount = amount?.toLamport(decimals: destinationDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolForEstimatedAmount(estimatedAmount, from: poolsPairs),
           let bestInputAmount = bestPoolsPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
        {
            bestPoolsPairSubject.accept(bestPoolsPair)
            inputAmountSubject.accept(bestInputAmount.convertToBalance(decimals: sourceDecimals))
        }
    }
    
    func changeSlippage(to slippage: Double) {
        Defaults.slippage = slippage
        slippageSubject.accept(slippage)
    }
    
    func reverseExchangeRate() {
        isExchangeRateReversedSubject.accept(!isExchangeRateReversedSubject.value)
    }
    
    func changePayingToken(to payingToken: PayingToken) {
        Defaults.payingToken = payingToken
        fixPayingToken()
    }
}

// MARK: - Helpers
private extension OrcaSwapV2.ViewModel {
    func fixPayingToken() {
        var payingToken = Defaults.payingToken
        
        // Force using native sol when source or destination is nativeSOL
        if sourceWalletSubject.value?.isNativeSOL == true ||
            destinationWalletSubject.value?.isNativeSOL == true // FIXME: - Fee relayer will support case where destination is native sol
        {
            payingToken = .nativeSOL
        }
        
        payingTokenSubject.accept(payingToken)
    }
    
    /// Verify error in current context IN ORDER
    /// - Returns: String or nil if no error
    func verify() -> OrcaSwapV2.VerificationError? {
        // loading state
        if loadingStateSubject.value != .loaded {
            return .swappingIsNotAvailable
        }
        
        // source wallet
        guard let sourceWallet = sourceWalletSubject.value else {
            return .sourceWalletIsEmpty
        }
        
        // destination wallet
        guard let destinationWallet = destinationWalletSubject.value else {
            return .destinationWalletIsEmpty
        }
        
        // prevent swap the same token
        if sourceWallet.token.address == destinationWallet.token.address {
            return .canNotSwapToItSelf
        }
        
        // pools pairs
        if tradablePoolsPairsSubject.state != .loaded {
            return .tradablePoolsPairsNotLoaded
        }
        
        // fees
        guard let fees = feesSubject.value?.totalFee?.lamports else {
            return .couldNotCalculatingFees
        }
        
        // inputAmount
        guard let inputAmount = inputAmountSubject.value else {
            return .inputAmountIsEmpty
        }
        
        if inputAmount.rounded(decimals: sourceWallet.token.decimals) <= 0 {
            return .inputAmountIsNotValid
        }
        
        if inputAmount > calculateAvailableAmount() {
            return .insufficientFunds
        }
        
        // estimated amount
        guard let estimatedAmount = estimatedAmountSubject.value else {
            return .estimatedAmountIsNotValid
        }
        
        if estimatedAmount.rounded(decimals: destinationWallet.token.decimals) <= 0 {
            return .estimatedAmountIsNotValid
        }
        
        // best pools pairs
        if bestPoolsPairSubject.value == nil {
            return .bestPoolsPairsIsEmpty
        }
        
        // paying with SOL
        if payingTokenSubject.value == .nativeSOL {
            guard let wallet = walletsRepository.nativeWallet else {
                return .nativeWalletNotFound
            }
            
            if fees > (wallet.lamports ?? 0) {
                return .notEnoughSOLToCoverFees
            }
        }
        
        // paying with SPL token
        else {
            // TODO: - fee compensation
            //                if feeCompensationPool == nil {
            //                    return L10n.feeCompensationPoolNotFound
            //                }
            if fees > (sourceWallet.lamports ?? 0) {
                return .notEnoughBalanceToCoverFees
            }
        }
        
        // slippage
        if !isSlippageValid() {
            return .slippageIsNotValid
        }
        
        return nil
    }
    
    private func calculateAvailableAmount() -> Double? {
        guard let sourceWallet = sourceWalletSubject.value,
              let fees = feesSubject.value?.totalFee?.lamports
        else {return sourceWalletSubject.value?.amount}
        
        // paying with native wallet
        if payingTokenSubject.value == .nativeSOL && !sourceWallet.isNativeSOL {
            return sourceWallet.amount
        }
        
        // paying with wallet itself
        else {
            let availableAmount = (sourceWallet.amount ?? 0) - fees.convertToBalance(decimals: sourceWallet.token.decimals)
            return availableAmount > 0 ? availableAmount: 0
        }
    }
    
    private func isSlippageValid() -> Bool {
        slippageSubject.value <= .maxSlippage && slippageSubject.value > 0
    }
}
