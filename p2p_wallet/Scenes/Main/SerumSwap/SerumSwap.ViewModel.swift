//
//  SerumSwap.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SerumSwap {
    class ViewModel: SerumSwapViewModelType {
        // MARK: - Dependencies
        private let provider: SwapProviderType
        private let analyticsManager: AnalyticsManager
        private let authenticationHandler: AuthenticationHandler
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var defaultsDisposables = [DefaultsDisposable]()
        fileprivate var isSelectingSourceWallet = true
        
        // MARK: - Input
        let inputAmountSubject: PublishRelay<String?> = .init()
        let estimatedAmountSubject: PublishRelay<String?> = .init()
        private let useAllBalanceSubject = PublishRelay<Double?>()
        
        // MARK: - Subject
        private let navigationRelay = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        
        private let sourceWalletRelay = BehaviorRelay<Wallet?>(value: nil)
        private let inputAmountRelay = BehaviorRelay<Double?>(value: nil)
        
        private let destinationWalletRelay = BehaviorRelay<Wallet?>(value: nil)
        private let estimatedAmountRelay = BehaviorRelay<Double?>(value: nil)
        
        private let exchangeRateRelay = BehaviorRelay<Double?>(value: nil)
        
        private let slippageRelay = BehaviorRelay<Double?>(value: nil)
        
        private let errorRelay = BehaviorRelay<String?>(value: nil)
        
        // MARK: - Initializer
        init(
            provider: SwapProviderType,
            analyticsManager: AnalyticsManager,
            authenticationHandler: AuthenticationHandler,
            sourceWallet: Wallet? = nil,
            destinationWallet: Wallet? = nil
        ) {
            self.provider = provider
            self.analyticsManager = analyticsManager
            self.authenticationHandler = authenticationHandler
            bind()
            
            sourceWalletRelay.accept(sourceWallet)
            destinationWalletRelay.accept(destinationWallet)
        }
        
        /// Bind subjects
        private func bind() {
            // bind input
            inputAmountSubject
                .map {$0?.double}
                .bind(to: inputAmountRelay)
                .disposed(by: disposeBag)
            
            estimatedAmountSubject
                .map {$0?.double}
                .bind(to: estimatedAmountRelay)
                .disposed(by: disposeBag)
            
            // exchange rate
            Observable.combineLatest(
                sourceWalletRelay,
                destinationWalletRelay
            )
                .do(onNext: {[weak self] _ in
                    self?.isLoadingRelay.accept(true)
                    self?.exchangeRateRelay.accept(nil)
                })
                .flatMap { [weak self] sourceWallet, destinationWallet -> Single<Double?> in
                    guard let self = self else {throw SolanaSDK.Error.unknown}
                    guard let sourceWallet = sourceWallet, let destinationWallet = destinationWallet
                    else {return .just(nil)}
                    return self.provider.loadPrice(fromMint: sourceWallet.mintAddress, toMint: destinationWallet.mintAddress)
                        .map(Optional.init)
                }
                .do(afterNext: {[weak self] _ in
                    self?.isLoadingRelay.accept(false)
                }, afterError: {[weak self] _ in
                    self?.isLoadingRelay.accept(false)
                    self?.errorRelay.accept(L10n.couldNotRetrieveExchangeRate)
                })
                .bind(to: exchangeRateRelay)
                .disposed(by: disposeBag)
            
            // estimating
            Observable.combineLatest(
                inputAmountSubject.map {$0?.double},
                exchangeRateRelay,
                slippageRelay
            )
                .map {calculateEstimatedAmount(inputAmount: $0, rate: $1, slippage: $2)}
                .bind(to: estimatedAmountRelay)
                .disposed(by: disposeBag)
            
            Observable.combineLatest(
                estimatedAmountSubject.map {$0?.double},
                exchangeRateRelay,
                slippageRelay
            )
                .map {calculateNeededInputAmount(forReceivingEstimatedAmount: $0, rate: $1, slippage: $2)}
                .bind(to: inputAmountRelay)
                .disposed(by: disposeBag)
            
            // error
            Observable.combineLatest(
                sourceWalletRelay,
                inputAmountRelay,
                destinationWalletRelay,
                exchangeRateRelay,
                slippageRelay
            )
                .map {
                    validate(
                        sourceWallet: $0,
                        inputAmount: $1,
                        destinationWallet: $2,
                        exchangeRate: $3,
                        slippage: $4
                    )
                }
                .bind(to: errorRelay)
                .disposed(by: disposeBag)
        }
        
        fileprivate func swap() {
//            analyticsManager.log(event: .swapSwapClick(tokenA: sourceWallet.token.symbol, tokenB: destinationWallet.token.symbol, sumA: inputAmount, sumB: estimatedAmount))
        }
    }
}

extension SerumSwap.ViewModel {
    // MARK: - Output
    var navigationDriver: Driver<SerumSwap.NavigatableScene?> { navigationRelay.asDriver() }
    var isLoadingDriver: Driver<Bool> { isLoadingRelay.asDriver() }
    var sourceWalletDriver: Driver<Wallet?> { sourceWalletRelay.asDriver() }
    var availableAmountDriver: Driver<Double?> {
        sourceWalletRelay
            .map {calculateAvailableAmount(sourceWallet: $0)}
            .asDriver(onErrorJustReturn: nil)
    }
    var inputAmountDriver: Driver<Double?> { inputAmountRelay.asDriver() }
    var destinationWalletDriver: Driver<Wallet?> { destinationWalletRelay.asDriver() }
    var estimatedAmountDriver: Driver<Double?> { estimatedAmountRelay.asDriver() }
    var errorDriver: Driver<String?> { errorRelay.asDriver() }
    var exchangeRateDriver: Driver<Double?> { exchangeRateRelay.asDriver() }
    var slippageDriver: Driver<Double?> { slippageRelay.asDriver() }
    var isSwappableDriver: Driver<Bool> {
        errorRelay.map {$0 == nil}.asDriver(onErrorJustReturn: false)
    }
    
    var useAllBalanceDidTapSignal: Signal<Double?> {useAllBalanceSubject.asSignal(onErrorJustReturn: nil)}
}

extension SerumSwap.ViewModel {
    // MARK: - Actions
    func navigate(to scene: SerumSwap.NavigatableScene) {
        switch scene {
        case .chooseSourceWallet:
            isSelectingSourceWallet = true
        case .chooseDestinationWallet:
            isSelectingSourceWallet = false
        case .settings:
            log(.swapSettingsClick)
        case .chooseSlippage:
            log(.swapSlippageClick)
        case .processTransaction:
            break
        }
        navigationRelay.accept(scene)
    }
    
    func useAllBalance() {
        guard let amount = calculateAvailableAmount(sourceWallet: sourceWalletRelay.value)
        else {return}
        analyticsManager.log(event: .swapAvailableClick(sum: amount))
        useAllBalanceSubject.accept(amount)
    }
    
    func log(_ event: AnalyticsEvent) {
        analyticsManager.log(event: event)
    }
    
    func swapSourceAndDestination() {
        analyticsManager.log(event: .swapReverseClick)
        let sourceWallet = sourceWalletRelay.value
        sourceWalletRelay.accept(destinationWalletRelay.value)
        destinationWalletRelay.accept(sourceWallet)
    }
    
    func authenticateAndSwap() {
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
    
    func changeSlippage(to slippage: Double) {
        log(.swapSlippageKeydown(slippage: slippage))
        slippageRelay.accept(slippage)
    }
    
    func getSourceWallet() -> Wallet? {
        sourceWalletRelay.value
    }
    
    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
            sourceWalletRelay.accept(wallet)
        } else {
            analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
            destinationWalletRelay.accept(wallet)
        }
    }
}

// MARK: - Calculation
private func calculateAvailableAmount(
    sourceWallet: Wallet?
) -> Double? {
    sourceWallet?.amount
}

private func calculateEstimatedAmount(
    inputAmount: Double?,
    rate: Double?,
    slippage: Double?
) -> Double? {
    guard let inputAmount = inputAmount,
          let rate = rate,
          let slippage = slippage
    else {return nil}
    return inputAmount * rate * (1 - slippage)
}

private func calculateNeededInputAmount(
    forReceivingEstimatedAmount estimatedAmount: Double?,
    rate: Double?,
    slippage: Double?
) -> Double? {
    guard let estimatedAmount = estimatedAmount,
          let rate = rate,
          rate != 0
    else {return nil}
    return estimatedAmount / rate * (1 + slippage)
}

/// Verify current context
/// - Returns: Error string, nil if no error appear
private func validate(
    sourceWallet: Wallet?,
    inputAmount: Double?,
    destinationWallet: Wallet?,
    exchangeRate: Double?,
    slippage: Double?
) -> String? {
    // if some params are missing
    guard let sourceWallet = sourceWallet,
          let inputAmount = inputAmount,
          let destinationWallet = destinationWallet,
          let exchangeRate = exchangeRate,
          let slippage = slippage
    else {return L10n.someParametersAreMissing}
    
    // verify amount
    if inputAmount <= 0 {return L10n.amountIsNotValid}
    if inputAmount > calculateAvailableAmount(sourceWallet: sourceWallet) {return L10n.insufficientFunds}
    
    // verify exchange rate
    if exchangeRate == 0 {return L10n.exchangeRateIsNotValid}
    
    // verify slippage
    if !isSlippageValid(slippage: slippage) {return L10n.slippageIsnTValid}
    
    // verify tokens
    if sourceWallet.token.address == destinationWallet.token.address {
        return L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.token.address)
    }
    
    return nil
}

private func isSlippageValid(slippage: Double) -> Bool {
    slippage <= .maxSlippage && slippage > 0
}
