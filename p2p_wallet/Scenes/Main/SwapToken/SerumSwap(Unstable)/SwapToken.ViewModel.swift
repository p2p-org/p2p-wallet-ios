//
//  SwapToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxCocoa
import RxSwift

protocol SwapTokenViewModelType: WalletDidSelectHandler {
    // Input
    var inputAmountSubject: PublishRelay<String?> { get }
    var estimatedAmountSubject: PublishRelay<String?> { get }

    // Drivers
    var navigationDriver: Driver<SerumSwapV1.NavigatableScene?> { get }
    var initialStateDriver: Driver<LoadableState> { get }

    var sourceWalletDriver: Driver<Wallet?> { get }
    var availableAmountDriver: Driver<Double?> { get }
    var inputAmountDriver: Driver<Double?> { get }

    var destinationWalletDriver: Driver<Wallet?> { get }
    var estimatedAmountDriver: Driver<Double?> { get }

    var exchangeRateDriver: Driver<Loadable<Double>> { get }
    var minOrderSizeDriver: Driver<Loadable<Double>> { get }

    var slippageDriver: Driver<Double> { get }

    var feesDriver: Driver<Loadable<[PayingFee]>> { get }

    var payingTokenMintDriver: Driver<String> { get }

    var errorDriver: Driver<String?> { get }

    var isExchangeRateReversedDriver: Driver<Bool> { get }

    // Signals
    var useAllBalanceDidTapSignal: Signal<Double?> { get }

    // Actions
    func reload()
    func calculateExchangeRateFeesAndMinOrderSize()
    func navigate(to: SerumSwapV1.NavigatableScene)
    func useAllBalance()
    func log(_ event: AnalyticsEvent)
    func swapSourceAndDestination()
    func reverseExchangeRate()
    func authenticateAndSwap()
    func changeSlippage(to slippage: Double)
    func changePayingTokenMint(to payingTokenMint: String)
    func getSourceWallet() -> Wallet?
    func providerSignatureView() -> UIView
}

extension SerumSwapV1 {
    class ViewModel {
        // MARK: - Dependencies

        private let provider: SwapProviderType
        private let feeAPIClient: FeeAPIClient
        private let walletsRepository: WalletsRepository
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var authenticationHandler: AuthenticationHandlerType

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
        private let feesRelay: LoadableRelay<[PayingFee]>
        private let minOrderSizeRelay: LoadableRelay<Double>

        private let slippageRelay = BehaviorRelay<Double>(value: Defaults.slippage)
        private let payingTokenMintRelay = BehaviorRelay<String>(value: Defaults.payingTokenMint)

        private let isExchangeRateReversed = BehaviorRelay<Bool>(value: false)

        // MARK: - Initializer

        init(
            provider: SwapProviderType,
            feeAPIClient: FeeAPIClient,
            walletsRepository: WalletsRepository,
            sourceWallet: Wallet? = nil,
            destinationWallet: Wallet? = nil
        ) {
            self.provider = provider
            self.feeAPIClient = feeAPIClient
            self.walletsRepository = walletsRepository
            lamportsPerSignatureRelay = .init(
                request: feeAPIClient.getLamportsPerSignature()
            )
            creatingAccountFeeRelay = .init(
                request: feeAPIClient.getCreatingTokenAccountFee()
            )
            exchangeRateRelay = .init(request: .just(0)) // placeholder, change request later
            feesRelay = .init(request: .just([])) // placeholder, change request later
            minOrderSizeRelay = .init(request: .just(0)) // placeholder, change request later
            bind()

            sourceWalletRelay.accept(sourceWallet)
            destinationWalletRelay.accept(destinationWallet)

            reload()
        }

        /// Bind subjects
        private func bind() {
            // bind input
            inputAmountSubject
                .map { $0?.double }
                .bind(to: inputAmountRelay)
                .disposed(by: disposeBag)

            estimatedAmountSubject
                .map { $0?.double }
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
            .subscribe(onNext: { [weak self] _ in
                self?.calculateExchangeRateFeesAndMinOrderSize()
            })
            .disposed(by: disposeBag)

            exchangeRateRelay
                .stateObservable
                .filter { $0 == .loaded }
                .subscribe(onNext: { [weak self] _ in
                    self?.feesRelay.reload()
                    self?.minOrderSizeRelay.reload()
                })
                .disposed(by: disposeBag)

            // estimating
            Observable.combineLatest(
                inputAmountSubject.map { $0?.double },
                exchangeRateRelay.valueObservable,
                slippageRelay
            )
            .map { [weak self] in
                self?.provider.calculateEstimatedAmount(
                    inputAmount: $0,
                    rate: $1,
                    slippage: $2
                )
            }
            .bind(to: estimatedAmountRelay)
            .disposed(by: disposeBag)

            Observable.combineLatest(
                estimatedAmountSubject.map { $0?.double },
                exchangeRateRelay.valueObservable,
                slippageRelay
            )
            .map { [weak self] in
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
                  let fees = feesRelay.value
            else { return }

            let slippage = slippageRelay.value

            // log
            log(.swapSwapClick(tokenA: sourceWallet.token.symbol, tokenB: destinationWallet.token.symbol, sumA: inputAmount, sumB: estimatedAmount))

            // show processing scene
//            navigate(
//                to: .processTransaction(
//                    request: .just(""),
//                    transactionType: .swap(
//                        provider: provider,
//                        from: sourceWallet,
//                        to: destinationWallet,
//                        inputAmount: inputAmount,
//                        estimatedAmount: estimatedAmount,
//                        fees: fees,
//                        slippage: slippage,
//                        isSimulation: false
//                    )
//                )
//            )
        }
    }
}

extension SerumSwapV1.ViewModel: SwapTokenViewModelType {
    // MARK: - Output

    var navigationDriver: Driver<SerumSwapV1.NavigatableScene?> {
        navigationRelay.asDriver()
    }

    var initialStateDriver: Driver<LoadableState> {
        Observable.combineLatest([
            lamportsPerSignatureRelay.stateObservable,
            creatingAccountFeeRelay.stateObservable,
        ])
        .map { $0.combined }
        .asDriver(onErrorJustReturn: .notRequested)
    }

    var sourceWalletDriver: Driver<Wallet?> { sourceWalletRelay.asDriver() }
    var availableAmountDriver: Driver<Double?> {
        Observable.combineLatest(
            sourceWalletRelay,
            feesRelay.valueObservable
        )
        .map { [weak self] in self?.provider.calculateAvailableAmount(sourceWallet: $0, fees: $1) }
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
            Driver.combineLatest(
                exchangeRateDriver,
                feesDriver,
                minOrderSizeDriver
            ),
            slippageDriver
        )
        .map { [weak self] initialState, sourceWallet, inputAmount, destinationWallet, estimatedAmount, providerInfo, slippage -> String? in
            guard let self = self else { return nil }
            return validate(
                provider: self.provider,
                initialState: initialState,
                sourceWallet: sourceWallet,
                inputAmount: inputAmount,
                destinationWallet: destinationWallet,
                estimatedAmount: estimatedAmount,
                exchangeRate: providerInfo.0,
                fees: providerInfo.1,
                solWallet: self.walletsRepository.nativeWallet,
                slippage: slippage,
                minOrderSize: providerInfo.2
            )
        }
    }

    var exchangeRateDriver: Driver<Loadable<Double>> { exchangeRateRelay.asDriver() }
    var minOrderSizeDriver: Driver<Loadable<Double>> { minOrderSizeRelay.asDriver() }
    var feesDriver: Driver<Loadable<[PayingFee]>> { feesRelay.asDriver() }
    var payingTokenMintDriver: Driver<String> {
        payingTokenMintRelay.asDriver()
    }

    var slippageDriver: Driver<Double> { slippageRelay.asDriver() }
    var isExchangeRateReversedDriver: Driver<Bool> { isExchangeRateReversed.asDriver() }

    var useAllBalanceDidTapSignal: Signal<Double?> { useAllBalanceSubject.asSignal(onErrorJustReturn: nil) }
    func providerSignatureView() -> UIView {
        provider.logoView()
    }
}

extension SerumSwapV1.ViewModel {
    // MARK: - Actions

    func reload() {
        lamportsPerSignatureRelay.reload()
        creatingAccountFeeRelay.reload()
    }

    func calculateExchangeRateFeesAndMinOrderSize() {
        // reset exchange rate and fees
        exchangeRateRelay.flush()
        feesRelay.flush()
        minOrderSizeRelay.flush()

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

        minOrderSizeRelay.request = provider.calculateMinOrderSize(
            fromMint: sourceWallet.token.address,
            toMint: destinationWallet.token.address
        )

        // request exchange rate and fee (feesRelay will reload after exchangeRateRelay reloaded by a binding in function bind, it's faster because market has been cached after requesting exchange rate)
        exchangeRateRelay.reload()
    }

    func navigate(to scene: SerumSwapV1.NavigatableScene) {
        switch scene {
        case .chooseSourceWallet:
            isSelectingSourceWallet = true
        case .chooseDestinationWallet:
            isSelectingSourceWallet = false
        case .settings:
            log(.swapShowingSettings)
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
        guard let amount = provider.calculateAvailableAmount(sourceWallet: sourceWalletRelay.value, fees: feesRelay.value)
        else { return }
        analyticsManager.log(event: .swapAvailableClick(sum: amount))
        useAllBalanceSubject.accept(amount)
    }

    func log(_ event: AnalyticsEvent) {
        analyticsManager.log(event: event)
    }

    func swapSourceAndDestination() {
        analyticsManager.log(event: .swapReversing)
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

    func changePayingTokenMint(to payingTokenMint: String) {
        payingTokenMintRelay.accept(payingTokenMint)
    }

    func getSourceWallet() -> Wallet? {
        sourceWalletRelay.value
    }

    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapChangingTokenA(tokenAName: wallet.token.symbol))
            sourceWalletRelay.accept(wallet)
        } else {
            analyticsManager.log(event: .swapChangingTokenB(tokenBName: wallet.token.symbol))
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
    fees: Loadable<[PayingFee]>,
    solWallet: Wallet?,
    slippage: Double?,
    minOrderSize: Loadable<Double>
) -> String? {
    // if swap is initializing, loading exchange rate or calculating fees
    if [initialState, exchangeRate.state, fees.state].combined != .loaded {
        return nil
    }

    // verify fee
    if let fees = fees.value,
       let totalFee = fees.totalFee,
       totalFee.token.isNativeSOL,
       let balance = solWallet?.lamports
    {
        if balance < totalFee.lamports {
            return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
        }
    }

    // if some params are missing
    guard let sourceWallet = sourceWallet,
          let inputAmount = inputAmount,
          let destinationWallet = destinationWallet,
          let exchangeRate = exchangeRate.value,
          let fees = fees.value,
          let minOrderSize = minOrderSize.value,
          let slippage = slippage
    else { return L10n.someParametersAreMissing }

    // verify amount
    if inputAmount <= 0 { return L10n.amountIsNotValid }
    if inputAmount < minOrderSize { return L10n.amountIsTooSmall }

    // verify if input amount
    if inputAmount.isGreaterThan(
        provider.calculateAvailableAmount(sourceWallet: sourceWallet, fees: fees),
        decimals: sourceWallet.token.decimals
    ) { return L10n.insufficientFunds }

    // verify estimated amount
    if estimatedAmount == 0 {
        return L10n.amountIsTooSmall
    }

    // verify exchange rate
    if exchangeRate == 0 { return L10n.exchangeRateIsNotValid }

    // verify slippage
    if !isSlippageValid(slippage: slippage) { return L10n.slippageIsnTValid }

    // verify tokens
    if sourceWallet.token.address == destinationWallet.token.address {
        return L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.token.address)
    }

    return nil
}

private func isSlippageValid(slippage: Double) -> Bool {
    slippage <= .maxSlippage && slippage > 0
}
