//
//  SwapToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SwapToken {
    class ViewModel {
        // MARK: - Dependencies
        private let provider: SwapProviderType
        private let apiClient: SwapTokenApiClient
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
        private let lamportsPerSignatureRelay: LoadableRelay<SolanaSDK.Lamports>
        private let creatingAccountFeeRelay: LoadableRelay<SolanaSDK.Lamports>
        
        private let navigationRelay = BehaviorRelay<NavigatableScene?>(value: nil)
        
        private let sourceWalletRelay = BehaviorRelay<Wallet?>(value: nil)
        private let inputAmountRelay = BehaviorRelay<Double?>(value: nil)
        
        private let destinationWalletRelay = BehaviorRelay<Wallet?>(value: nil)
        private let estimatedAmountRelay = BehaviorRelay<Double?>(value: nil)
        
        private var exchangeRateRelay: LoadableRelay<Double>
        private let feesRelay: LoadableRelay<[FeeType: SwapFee]>
        
        private let slippageRelay = BehaviorRelay<Double?>(value: Defaults.slippage)
        private let payingTokenRelay = BehaviorRelay<PayingToken>(value: Defaults.payingToken)
        
        private let isExchangeRateReversed = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Initializer
        init(
            provider: SwapProviderType,
            apiClient: SwapTokenApiClient,
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
            self.lamportsPerSignatureRelay = .init(
                request: apiClient.getLamportsPerSignature()
            )
            self.creatingAccountFeeRelay = .init(
                request: apiClient.getCreatingTokenAccountFee()
            )
            self.exchangeRateRelay = .init(request: .just(0)) // placeholder, change request later
            self.feesRelay = .init(request: .just([:])) // placeholder, change request later
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
            
            // exchange rate, fees
            Observable.combineLatest(
                sourceWalletRelay.distinctUntilChanged(),
                destinationWalletRelay.distinctUntilChanged(),
                lamportsPerSignatureRelay.valueObservable,
                creatingAccountFeeRelay.valueObservable
            )
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: {[weak self] _ in
                    self?.calculateExchangeRateAndFees()
                })
                .disposed(by: disposeBag)
            
            exchangeRateRelay
                .stateObservable
                .filter {$0 == .loaded}
                .subscribe(onNext: {[weak self] _ in
                    self?.feesRelay.reload()
                })
                .disposed(by: disposeBag)
            
            // estimating
            Observable.combineLatest(
                inputAmountSubject.map {$0?.double},
                exchangeRateRelay.valueObservable,
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
                exchangeRateRelay.valueObservable,
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
        }
        
        fileprivate func swap() {
            guard let sourceWallet = sourceWalletRelay.value,
                  let destinationWallet = destinationWalletRelay.value,
                  let inputAmount = inputAmountRelay.value,
                  let estimatedAmount = estimatedAmountRelay.value,
                  let fee = feesRelay.value?[.default],
                  let slippage = slippageRelay.value
            else {return}
            
            
            // log
            log(.swapSwapClick(tokenA: sourceWallet.token.symbol, tokenB: destinationWallet.token.symbol, sumA: inputAmount, sumB: estimatedAmount))
            
            // show processing scene
            navigate(
                to: .processTransaction(
                    request: .just(""),
                    transactionType: .swap(
                        provider: provider,
                        from: sourceWallet,
                        to: destinationWallet,
                        inputAmount: inputAmount,
                        estimatedAmount: estimatedAmount,
                        networkFee: fee,
                        slippage: slippage,
                        isSimulation: false
                    )
                )
            )
        }
    }
}

extension SwapToken.ViewModel: SwapTokenViewModelType {
    // MARK: - Output
    var navigationDriver: Driver<SwapToken.NavigatableScene?> {
        navigationRelay.asDriver()
    }
    var initialStateDriver: Driver<LoadableState> {
        Observable.combineLatest([
            lamportsPerSignatureRelay.stateObservable,
            creatingAccountFeeRelay.stateObservable
        ])
            .map {$0.combined}
            .asDriver(onErrorJustReturn: .notRequested)
    }
    var sourceWalletDriver: Driver<Wallet?> { sourceWalletRelay.asDriver() }
    var availableAmountDriver: Driver<Double?> {
        Observable.combineLatest(
            sourceWalletRelay,
            feesRelay.valueObservable
        )
            .map {[weak self] in self?.provider.calculateAvailableAmount(sourceWallet: $0, fee: $1?[.default])}
            .asDriver(onErrorJustReturn: nil)
    }
    var inputAmountDriver: Driver<Double?> { inputAmountRelay.asDriver() }
    var destinationWalletDriver: Driver<Wallet?> { destinationWalletRelay.asDriver() }
    var estimatedAmountDriver: Driver<Double?> { estimatedAmountRelay.asDriver() }
    var errorDriver: Driver<String?> {
        Driver.combineLatest(
            initialStateDriver,
            sourceWalletDriver,
            inputAmountDriver,
            destinationWalletDriver,
            estimatedAmountDriver,
            exchangeRateDriver,
            feesDriver,
            slippageDriver
        )
            .map {[weak self] initialState, sourceWallet, inputAmount, destinationWallet, estimatedAmount, exchangeRate, fees, slippage -> String? in
                guard let self = self else {return nil}
                return validate(
                    provider: self.provider,
                    initialState: initialState,
                    sourceWallet: sourceWallet,
                    inputAmount: inputAmount,
                    destinationWallet: destinationWallet,
                    estimatedAmount: estimatedAmount,
                    exchangeRate: exchangeRate,
                    fees: fees,
                    solWallet: self.walletsRepository.nativeWallet,
                    slippage: slippage
                )
            }
    }
    var exchangeRateDriver: Driver<Loadable<Double>> { exchangeRateRelay.asDriver() }
    var feesDriver: Driver<Loadable<[FeeType: SwapFee]>> { feesRelay.asDriver() }
    var payingTokenDriver: Driver<PayingToken> {
        payingTokenRelay.asDriver()
    }
    var slippageDriver: Driver<Double?> { slippageRelay.asDriver() }
    var isExchangeRateReversedDriver: Driver<Bool> {isExchangeRateReversed.asDriver()}
    
    var useAllBalanceDidTapSignal: Signal<Double?> {useAllBalanceSubject.asSignal(onErrorJustReturn: nil)}
    func providerSignatureView() -> UIView {
        provider.logoView()
    }
}

extension SwapToken.ViewModel {
    // MARK: - Actions
    func reload() {
        lamportsPerSignatureRelay.reload()
        creatingAccountFeeRelay.reload()
    }
    
    func calculateExchangeRateAndFees() {
        // reset exchange rate and fees
        exchangeRateRelay.flush()
        feesRelay.flush()
        isExchangeRateReversed.accept(false)
        
        // if source wallet or destinationWallet is undefined
        guard let sourceWallet = sourceWalletRelay.value,
              let destinationWallet = destinationWalletRelay.value,
              let lamportsPerSignature = lamportsPerSignatureRelay.value,
              let creatingAccountFee = creatingAccountFeeRelay.value
        else { return }
        
        // if two mint are equal
        if sourceWallet.mintAddress == destinationWallet.mintAddress {
            return
        }

        // form request
        exchangeRateRelay.request = provider
            .loadPrice(fromMint: sourceWallet.mintAddress, toMint: destinationWallet.mintAddress)

        feesRelay.request = provider.calculateFees(
            sourceWallet: sourceWallet,
            destinationWallet: destinationWallet,
            lamportsPerSignature: lamportsPerSignature,
            creatingAccountFee: creatingAccountFee
        )
        
        // request exchange rate and fee (feesRelay will reload after exchangeRateRelay reloaded by a binding in function bind, it's faster because market has been cached after requesting exchange rate)
        exchangeRateRelay.reload()
    }
    
    func navigate(to scene: SwapToken.NavigatableScene) {
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
        guard let amount = provider.calculateAvailableAmount(sourceWallet: sourceWalletRelay.value, fee: feesRelay.value?[.default])
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
    
    func reverseExchangeRate() {
        isExchangeRateReversed.accept(!isExchangeRateReversed.value)
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
/// - Returns: Error string, nil if no error appear or some params are unfilled
private func validate(
    provider: SwapProviderType,
    initialState: LoadableState,
    sourceWallet: Wallet?,
    inputAmount: Double?,
    destinationWallet: Wallet?,
    estimatedAmount: Double?,
    exchangeRate: Loadable<Double>,
    fees: Loadable<[FeeType: SwapFee]>,
    solWallet: Wallet?,
    slippage: Double?
) -> String? {
    // if swap is initializing, loading exchange rate or calculating fees
    if [initialState, exchangeRate.state, fees.state].combined != .loaded
    {
        return nil
    }
    
    // verify fee
    if let fees = fees.value,
       fees[.default]?.token.symbol == "SOL",
       let balance = solWallet?.lamports,
       let fee = fees[.default]?.lamports
    {
        if balance < fee {
            return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
        }
    }
    
    // if some params are missing
    guard let sourceWallet = sourceWallet,
          let inputAmount = inputAmount,
          let destinationWallet = destinationWallet,
          let exchangeRate = exchangeRate.value,
          let fees = fees.value,
          let slippage = slippage
    else {return L10n.someParametersAreMissing}
    
    // verify amount
    if inputAmount <= 0 {return L10n.amountIsNotValid}
    
    // verify if input amount
    if inputAmount.isGreaterThan(
        provider.calculateAvailableAmount(sourceWallet: sourceWallet, fee: fees[.default]),
        decimals: sourceWallet.token.decimals
    ) {return L10n.insufficientFunds}
    
    // verify estimated amount
    if estimatedAmount == 0 {
        return L10n.amountIsTooSmall
    }
    
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
