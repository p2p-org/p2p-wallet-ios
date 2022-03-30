//
//  OrcaSwapV2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxCocoa
import RxSwift

extension OrcaSwapV2 {
    class ViewModel {
        // MARK: - Dependencies

        @Injected var authenticationHandler: AuthenticationHandlerType
        @Injected var analyticsManager: AnalyticsManagerType
        @Injected var feeService: FeeServiceType
        @Injected var swapService: Swap.Service
        @Injected var walletsRepository: WalletsRepository
        @Injected var notificationsService: NotificationsServiceType
        @Injected var pricesService: PricesServiceType

        // MARK: - Properties

        let disposeBag = DisposeBag()
        var isSelectingSourceWallet = false // indicate if selecting source wallet or destination wallet
        var isUsingAllBalance = false

        // MARK: - Subject

        let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let tradablePoolsPairsSubject = LoadableRelay<[Swap.PoolsPair]>(request: .just([]))
        let bestPoolsPairSubject = BehaviorRelay<Swap.PoolsPair?>(value: nil)
        let availableAmountSubject = BehaviorRelay<Double?>(value: nil)
        let inputAmountSubject = BehaviorRelay<Double?>(value: nil)
        let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        let feesSubject = LoadableRelay<[PayingFee]>(request: .just([]))
        let slippageSubject = BehaviorRelay<Double>(value: Defaults.slippage)
        let payingWalletSubject = BehaviorRelay<Wallet?>(value: nil)

        let errorSubject = BehaviorRelay<VerificationError?>(value: nil)
        let showHideDetailsButtonTapSubject = PublishRelay<Void>()
        let isShowingDetailsSubject = BehaviorRelay<Bool>(value: false)

        // MARK: - setter

        init(
            initialWallet: Wallet?
        ) {
            payingWalletSubject.accept(walletsRepository.nativeWallet)
            reload()
            bind(initialWallet: initialWallet ?? walletsRepository.nativeWallet)
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func bind(initialWallet: Wallet?) {
            // wait until loaded and choose initial wallet
            if let initialWallet = initialWallet {
                loadingStateSubject
                    .take(until: { $0 == .loaded })
                    .take(1)
                    .subscribe(onNext: { [weak self] _ in
                        self?.sourceWalletSubject.accept(initialWallet)
                    })
                    .disposed(by: disposeBag)
            }

            // update wallet after swapping
            walletsRepository.dataObservable
                .skip(1)
                .subscribe(onNext: { [weak self] wallets in
                    if self?.sourceWalletSubject.value?.pubkey != nil,
                       let wallet = wallets?.first(where: { $0.pubkey == self?.sourceWalletSubject.value?.pubkey })
                    {
                        self?.sourceWalletSubject.accept(wallet)
                    }

                    if self?.destinationWalletSubject.value?.pubkey != nil,
                       let wallet = wallets?
                           .first(where: { $0.pubkey == self?.destinationWalletSubject.value?.pubkey })
                    {
                        self?.destinationWalletSubject.accept(wallet)
                    }
                })
                .disposed(by: disposeBag)

            // available amount
            Observable.combineLatest(
                sourceWalletSubject,
                payingWalletSubject,
                feesSubject.valueObservable
            )
                .map { sourceWallet, payingWallet, fees in
                    calculateAvailableAmount(
                        sourceWallet: sourceWallet,
                        payingFeeWallet: payingWallet,
                        fees: fees
                    )
                }
                .bind(to: availableAmountSubject)
                .disposed(by: disposeBag)

            // auto fill balance after tapping max
            availableAmountSubject
                .filter { [weak self] availableAmount in
                    guard let self = self else { return false }
                    return self.isUsingAllBalance && self.inputAmountSubject.value?
                        .rounded(decimals: self.sourceWalletSubject.value?.token.decimals) > availableAmount?
                        .rounded(decimals: self.sourceWalletSubject.value?.token.decimals)
                }
                .subscribe(onNext: { [weak self] availableAmount in
                    self?.isUsingAllBalance = false
                    self?.enterInputAmount(availableAmount)
                })
                .disposed(by: disposeBag)

            // get tradable pools pair for each token pair
            Observable.combineLatest(
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
                .subscribe(onNext: { [weak self] sourceWallet, destinationWallet in
                    guard let self = self,
                          let sourceWallet = sourceWallet,
                          let destinationWallet = destinationWallet
                    else {
                        self?.tradablePoolsPairsSubject.request = .just([])
                        self?.tradablePoolsPairsSubject.reload()
                        return
                    }

                    self.tradablePoolsPairsSubject.request = self.swapService.getPoolPair(
                        from: sourceWallet.token.address,
                        to: destinationWallet.token.address,
                        amount: 1000, // TODO: fix me
                        as: .source
                    )

                    self.tradablePoolsPairsSubject.reload()
                })
                .disposed(by: disposeBag)

            // Fill input amount and estimated amount after loaded
            tradablePoolsPairsSubject.stateObservable
                .distinctUntilChanged()
                .filter { $0 == .loaded }
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    if let inputAmount = self.inputAmountSubject.value {
                        self.enterInputAmount(inputAmount)
                    } else if let estimatedAmount = self.estimatedAmountSubject.value {
                        self.enterEstimatedAmount(estimatedAmount)
                    }
                })
                .disposed(by: disposeBag)

            // fees
            Observable.combineLatest(
                bestPoolsPairSubject,
                inputAmountSubject,
                slippageSubject,
                destinationWalletSubject,
                sourceWalletSubject,
                payingWalletSubject
            )
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.feesSubject.request = self.feesRequest()
                    self.feesSubject.reload()
                })
                .disposed(by: disposeBag)

            // Error
            Observable.combineLatest(
                loadingStateSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                tradablePoolsPairsSubject.stateObservable,
                bestPoolsPairSubject,
                feesSubject.valueObservable,
                slippageSubject,
                payingWalletSubject
            )
                .map { [weak self] _ in self?.verify() }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)

            showHideDetailsButtonTapSubject
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }

                    self.isShowingDetailsSubject.accept(!self.isShowingDetailsSubject.value)
                })
                .disposed(by: disposeBag)
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

        func swap() {
            guard verify() == nil else { return }

            let authority = walletsRepository.nativeWallet?.pubkey
            let sourceWallet = sourceWalletSubject.value!
            let destinationWallet = destinationWalletSubject.value!
            let bestPoolsPair = bestPoolsPairSubject.value!
            let inputAmount = inputAmountSubject.value!
            let estimatedAmount = estimatedAmountSubject.value!
            let payingWallet = payingWalletSubject.value
            let slippage = slippageSubject.value
            let fees = feesSubject.value?.filter { $0.type != .liquidityProviderFee } ?? []

            let swapMAX = availableAmountSubject.value == inputAmount

            // log
            minimumReceiveAmountObservable
                .first()
                .subscribe(onSuccess: { [weak self] receiveAmount in
                    guard let self = self else { return }

                    let receiveAmount: Double = receiveAmount.map { $0 ?? 0 } ?? 0
                    let receivePriceFiat: Double = destinationWallet.priceInCurrentFiat ?? 0.0
                    let swapUSD = receiveAmount * receivePriceFiat

                    // show processing scene
                    self.navigationSubject.accept(
                        .processTransaction(
                            ProcessTransaction.SwapTransaction(
                                swapService: self.swapService,
                                sourceWallet: sourceWallet,
                                destinationWallet: destinationWallet,
                                payingWallet: payingWallet,
                                authority: authority,
                                poolsPair: bestPoolsPair,
                                amount: inputAmount,
                                estimatedAmount: estimatedAmount,
                                slippage: slippage,
                                fees: fees,
                                metaInfo: .init(
                                    swapMAX: swapMAX,
                                    swapUSD: swapUSD
                                )
                            )
                        )
                    )
                })
                .disposed(by: disposeBag)
        }
    }
}

private func calculateAvailableAmount(
    sourceWallet: Wallet?,
    payingFeeWallet: Wallet?,
    fees: [PayingFee]?
) -> Double? {
    guard let sourceWallet = sourceWallet else {
        return nil
    }

    // subtract the fee when source wallet is the paying wallet
    if payingFeeWallet?.mintAddress == sourceWallet.mintAddress {
        let networkFees = fees?.networkFees(of: sourceWallet.token.symbol)?.total
            .convertToBalance(decimals: sourceWallet.token.decimals)

        if let networkFees = networkFees,
           let amount = sourceWallet.amount
        {
            if amount > networkFees {
                return amount - networkFees
            } else {
                return 0
            }
        }
    }

    return sourceWallet.amount
}
