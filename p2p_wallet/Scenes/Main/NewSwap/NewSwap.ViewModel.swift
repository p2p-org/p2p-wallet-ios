//
//  SerumSwap.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension NewSwap {
    class ViewModel {
        // MARK: - Dependencies
        private let provider: SwapProviderType
        private let apiClient: NewSwapViewModelAPIClient
        private let walletsRepository: WalletsRepository
        private let analyticsManager: AnalyticsManagerType
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
        
        private let slippageRelay = BehaviorRelay<Double?>(value: Defaults.slippage)
        private let payingTokenRelay = BehaviorRelay<PayingToken>(value: Defaults.payingToken)
        
        private let feesRelay = BehaviorRelay<[FeeType: SwapFee]>(value: [:])
        private var lamportsPerSignatureRelay = BehaviorRelay<SolanaSDK.Lamports?>(value: nil)
        private var creatingAccountFeeRelay = BehaviorRelay<SolanaSDK.Lamports?>(value: nil)
        
        private let errorRelay = BehaviorRelay<String?>(value: nil)
        
        // MARK: - Initializer
        init(
            provider: SwapProviderType,
            apiClient: NewSwapViewModelAPIClient,
            walletsRepository: WalletsRepository,
            analyticsManager: AnalyticsManagerType,
            authenticationHandler: AuthenticationHandler,
            sourceWallet: Wallet? = nil,
            destinationWallet: Wallet? = nil
        ) {
            self.provider = provider
            self.apiClient = apiClient
            self.walletsRepository = walletsRepository
            self.analyticsManager = analyticsManager
            self.authenticationHandler = authenticationHandler
            bind()
            
            sourceWalletRelay.accept(sourceWallet)
            destinationWalletRelay.accept(destinationWallet)
            
            reload()
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
                    if sourceWallet.mintAddress == destinationWallet.mintAddress {
                        return .just(nil)
                    }
                    return self.provider.loadPrice(fromMint: sourceWallet.mintAddress, toMint: destinationWallet.mintAddress)
                        .map(Optional.init)
                        .catch {[weak self] _ in
                            self?.isLoadingRelay.accept(false)
                            self?.errorRelay.accept(L10n.couldNotRetrieveExchangeRate)
                            return .just(nil)
                        }
                }
                .do(afterNext: {[weak self] _ in
                    self?.isLoadingRelay.accept(false)
                })
                .bind(to: exchangeRateRelay)
                .disposed(by: disposeBag)
            
            // estimating
            Observable.combineLatest(
                inputAmountSubject.map {$0?.double},
                exchangeRateRelay,
                slippageRelay
            )
                .map {[weak self] in
                    self?.provider.calculateEstimatedAmount(
                        inputAmount: $0,
                        rate: $1,
                        slippage: $2
                    )
                }
                .bind(to: estimatedAmountRelay)
                .disposed(by: disposeBag)
            
            Observable.combineLatest(
                estimatedAmountSubject.map {$0?.double},
                exchangeRateRelay,
                slippageRelay
            )
                .map {[weak self] in
                    self?.provider.calculateNeededInputAmount(
                        forReceivingEstimatedAmount: $0,
                        rate: $1,
                        slippage: $2
                    )
                }
                .bind(to: inputAmountRelay)
                .disposed(by: disposeBag)
            
            // fee
            Observable.combineLatest(
                sourceWalletRelay,
                destinationWalletRelay,
                lamportsPerSignatureRelay,
                creatingAccountFeeRelay
            )
                .flatMap {[weak self] in
                    self?.provider.calculateFees(
                        sourceWallet: $0,
                        destinationWallet: $1,
                        lamportsPerSignature: $2,
                        creatingAccountFee: $3)
                    ?? .just([:])
                }
                .catch {[weak self] _ in
                    self?.isLoadingRelay.accept(false)
                    self?.errorRelay.accept(L10n.couldNotRetrieveExchangeRate)
                    return .just([:])
                }
                .bind(to: feesRelay)
                .disposed(by: disposeBag)
            
            // error
            Observable.combineLatest(
                sourceWalletRelay,
                inputAmountRelay,
                destinationWalletRelay,
                estimatedAmountRelay,
                exchangeRateRelay,
                feesRelay,
                slippageRelay
            )
                .map { [weak self] params -> String? in
                    guard let self = self else {return nil}
                    return validate(
                        provider: self.provider,
                        sourceWallet: params.0,
                        inputAmount: params.1,
                        destinationWallet: params.2,
                        estimatedAmount: params.3,
                        exchangeRate: params.4,
                        fee: params.5[.default],
                        solWallet: self.walletsRepository.nativeWallet,
                        slippage: params.6
                    )
                }
                .bind(to: errorRelay)
                .disposed(by: disposeBag)
        }
        
        fileprivate func swap() {
            guard let sourceWallet = sourceWalletRelay.value,
                  let destinationWallet = destinationWalletRelay.value,
                  let inputAmount = inputAmountRelay.value,
                  let estimatedAmount = estimatedAmountRelay.value,
                  let slippage = slippageRelay.value
            else {return}
            let fee = feesRelay.value
            
            // log
            log(.swapSwapClick(tokenA: sourceWallet.token.symbol, tokenB: destinationWallet.token.symbol, sumA: inputAmount, sumB: estimatedAmount))
            
            // request
            let request = provider.swap(
                fromWallet: sourceWallet,
                toWallet: destinationWallet,
                amount: inputAmount,
                slippage: slippage,
                isSimulation: false
            )
                .map {$0 as ProcessTransactionResponseType}
            
            // show processing scene
            navigate(
                to: .processTransaction(
                    request: request,
                    transactionType: .swap(
                        from: sourceWallet,
                        to: destinationWallet,
                        inputAmount: inputAmount.toLamport(decimals: sourceWallet.token.decimals),
                        estimatedAmount: estimatedAmount.toLamport(decimals: destinationWallet.token.decimals),
                        fee: fee[.default]?.lamports ?? 0
                    )
                )
            )
        }
    }
}

extension NewSwap.ViewModel: NewSwapViewModelType {
    // MARK: - Output
    var navigationDriver: Driver<NewSwap.NavigatableScene?> { navigationRelay.asDriver() }
    var isLoadingDriver: Driver<Bool> { isLoadingRelay.asDriver() }
    var sourceWalletDriver: Driver<Wallet?> { sourceWalletRelay.asDriver() }
    var availableAmountDriver: Driver<Double?> {
        Observable.combineLatest(
            sourceWalletRelay,
            feesRelay
        )
            .map {[weak self] in self?.provider.calculateAvailableAmount(sourceWallet: $0, fee: $1[.default])}
            .asDriver(onErrorJustReturn: nil)
    }
    var inputAmountDriver: Driver<Double?> { inputAmountRelay.asDriver() }
    var destinationWalletDriver: Driver<Wallet?> { destinationWalletRelay.asDriver() }
    var estimatedAmountDriver: Driver<Double?> { estimatedAmountRelay.asDriver() }
    var errorDriver: Driver<String?> { errorRelay.asDriver() }
    var exchangeRateDriver: Driver<Double?> { exchangeRateRelay.asDriver() }
    var feesDriver: Driver<[FeeType: SwapFee]> { feesRelay.asDriver() }
    var payingTokenDriver: Driver<PayingToken> {
        payingTokenRelay.asDriver()
    }
    var slippageDriver: Driver<Double?> { slippageRelay.asDriver() }
    var isSwappableDriver: Driver<Bool> {
        errorRelay.map {$0 == nil}.asDriver(onErrorJustReturn: false)
    }
    
    var useAllBalanceDidTapSignal: Signal<Double?> {useAllBalanceSubject.asSignal(onErrorJustReturn: nil)}
    func providerSignatureView() -> UIView {
        provider.logoView()
    }
}

extension NewSwap.ViewModel {
    // MARK: - Actions
    func reload() {
        isLoadingRelay.accept(true)
        Single.zip(
            apiClient.getLamportsPerSignature(),
            apiClient.getCreatingTokenAccountFee()
        )
            .subscribe(onSuccess: {[weak self] lps, ctaFee in
                self?.isLoadingRelay.accept(false)
                self?.lamportsPerSignatureRelay.accept(lps)
                self?.creatingAccountFeeRelay.accept(ctaFee)
            }, onFailure: {error in
                Logger.log(message: error.readableDescription, event: .error)
                self.isLoadingRelay.accept(false)
                self.errorRelay.accept(L10n.swappingIsCurrentlyUnavailable)
            })
            .disposed(by: disposeBag)
    }
    
    func navigate(to scene: NewSwap.NavigatableScene) {
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
        case .swapFees:
            log(.swapSwapFeesClick)
        }
        navigationRelay.accept(scene)
    }
    
    func useAllBalance() {
        guard let amount = provider.calculateAvailableAmount(sourceWallet: sourceWalletRelay.value, fee: feesRelay.value[.default])
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
        inputAmountSubject.accept(nil)
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
    
    func changePayingToken(to payingToken: PayingToken) {
        payingTokenRelay.accept(payingToken)
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

/// Verify current context
/// - Returns: Error string, nil if no error appear
private func validate(
    provider: SwapProviderType,
    sourceWallet: Wallet?,
    inputAmount: Double?,
    destinationWallet: Wallet?,
    estimatedAmount: Double?,
    exchangeRate: Double?,
    fee: SwapFee?,
    solWallet: Wallet?,
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
    
    // verify if input amount
    if inputAmount.isGreaterThan(
        provider.calculateAvailableAmount(sourceWallet: sourceWallet, fee: fee),
        decimals: sourceWallet.token.decimals
    ) {return L10n.insufficientFunds}
    
    // verify estimated amount
    if estimatedAmount == 0 {
        return L10n.amountIsTooSmall
    }
    
    // verify exchange rate
    if exchangeRate == 0 {return L10n.exchangeRateIsNotValid}
    
    // verify fee
    if fee?.token.symbol == "SOL",
       let balance = solWallet?.lamports,
       let fee = fee?.lamports
    {
        if balance < fee {
            return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
        }
    }
    
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
