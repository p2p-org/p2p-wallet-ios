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

        // MARK: - Properties
        let disposeBag = DisposeBag()
        var isSelectingSourceWallet = false  // indicate if selecting source wallet or destination wallet

        // MARK: - Subject
        let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let tradablePoolsPairsSubject = LoadableRelay<[Swap.PoolsPair]>(request: .just([]))
        let bestPoolsPairSubject = BehaviorRelay<Swap.PoolsPair?>(value: nil)
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
                        let wallet = wallets?.first(where: { $0.pubkey == self?.destinationWalletSubject.value?.pubkey })
                    {
                        self?.destinationWalletSubject.accept(wallet)
                    }
                })
                .disposed(by: disposeBag)

            // get tradable pools pair for each token pair
            Observable.combineLatest(
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
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
                    amount: 1000,  // TODO: fix me
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
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
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

            let sourceWallet = sourceWalletSubject.value!
            let destinationWallet = destinationWalletSubject.value!
            let bestPoolsPair = bestPoolsPairSubject.value!
            let inputAmount = inputAmountSubject.value!
            let estimatedAmount = estimatedAmountSubject.value!
            let payingWallet = payingWalletSubject.value

            // log
            analyticsManager.log(
                event: .swapSwapClick(
                    tokenA: sourceWallet.token.symbol,
                    tokenB: destinationWallet.token.symbol,
                    sumA: inputAmount,
                    sumB: estimatedAmount
                )
            )
            
            // check if payingWallet has enough balance to cover fee
            let checkRequest: Completable
            if let fees = feesSubject.value?.networkFees,
               let payingWallet = payingWallet
            {
                checkRequest = swapService.calculateNetworkFeeInPayingToken(networkFee: fees, payingTokenMint: payingWallet.mintAddress)
                    .map { amount -> Bool in
                        if let amount = amount,
                            let currentAmount = payingWallet.lamports,
                            amount > currentAmount
                        {
                            throw SolanaSDK.Error.other(
                                L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                                + ". "
                                + L10n.needsAtLeast("\(amount.convertToBalance(decimals: payingWallet.token.decimals)) \(payingWallet.token.symbol)")
                                + ". "
                                + L10n.pleaseChooseAnotherTokenAndTryAgain
                            )
                        }
                        return true
                    }
                    .asCompletable()
            } else {
                checkRequest = .empty()
            }
            
            let request = checkRequest
                .andThen(
                    swapService.swap(
                        sourceAddress: sourceWallet.pubkey!,
                        sourceTokenMint: sourceWallet.mintAddress,
                        destinationAddress: destinationWallet.pubkey,
                        destinationTokenMint: destinationWallet.mintAddress,
                        payingTokenAddress: payingWallet?.pubkey,
                        payingTokenMint: payingWallet?.mintAddress,
                        poolsPair: bestPoolsPair,
                        amount: inputAmount.toLamport(decimals: sourceWallet.token.decimals),
                        slippage: slippageSubject.value
                    ).map { $0.first ?? "" as ProcessTransactionResponseType }
                )

            // show processing scene
            navigationSubject.accept(
                .processTransaction(
                    request: request,
                    transactionType: .orcaSwap(
                        from: sourceWallet,
                        to: destinationWallet,
                        inputAmount: inputAmount.toLamport(decimals: sourceWallet.token.decimals),
                        estimatedAmount: estimatedAmount.toLamport(decimals: destinationWallet.token.decimals),
                        fees: feesSubject.value?.filter { $0.type != .liquidityProviderFee } ?? []
                    )
                )
            )
        }
    }
}
