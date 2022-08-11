//
//  OrcaSwapV2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

extension OrcaSwapV2 {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected var authenticationHandler: AuthenticationHandlerType
        @Injected var analyticsManager: AnalyticsManager
        @Injected var swapService: Swap.Service
        @Injected var walletsRepository: WalletsRepository
        @Injected var notificationsService: NotificationService
        @Injected var pricesService: PricesServiceType

        // MARK: - Properties

        var subscriptions = [AnyCancellable]()
        var isSelectingSourceWallet = false // indicate if selecting source wallet or destination wallet
        var isUsingAllBalance = false

        // MARK: - Subject

        @Published var navigation: NavigatableScene?
        @Published var loadingState: LoadableState = .notRequested
        @Published var sourceWallet: Wallet?
        @Published var destinationWallet: Wallet?
        let tradablePoolsPairsSubject = LoadableRelay<[Swap.PoolsPair]>(request: { [] })
        @Published var bestPoolsPair: Swap.PoolsPair?
        @Published var availableAmount: Double?
        @Published var inputAmount: Double?
        @Published var estimatedAmount: Double?
        let feesSubject = LoadableRelay<[PayingFee]>(request: { [] })
        @Published var slippage: Double = Defaults.slippage
        @Published var payingWallet: Wallet?

        @Published var error: VerificationError?
        var showHideDetailsButtonTapSubject = PassthroughSubject<Void, Never>()
        @Published var isShowingDetails: Bool = false
        var activeInputField = ActiveInputField.none

        // MARK: - setter

        init(
            initialWallet: Wallet?
        ) {
            payingWallet = walletsRepository.nativeWallet
            reload()
            bind(initialWallet: initialWallet ?? walletsRepository.nativeWallet)
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        func bind(initialWallet: Wallet?) {
            // wait until loaded and choose initial wallet
            if let initialWallet = initialWallet {
                $loadingState
                    .filter { $0 == .loaded } // .take(until: { $0 == .loaded })
                    .prefix(1)
                    .sink { [weak self] _ in
                        self?.sourceWallet = initialWallet
                    }
                    .store(in: &subscriptions)
            }

            // update wallet after swapping
            walletsRepository.dataPublisher
                .dropFirst()
                .sink { [weak self] wallets in
                    if self?.sourceWallet?.pubkey != nil,
                       let wallet = wallets.first(where: { $0.pubkey == self?.sourceWallet?.pubkey })
                    {
                        self?.sourceWallet = wallet
                    }

                    if self?.destinationWallet?.pubkey != nil,
                       let wallet = wallets
                           .first(where: { $0.pubkey == self?.destinationWallet?.pubkey })
                    {
                        self?.destinationWallet = wallet
                    }
                }
                .store(in: &subscriptions)

            // available amount
            Publishers.CombineLatest3(
                $sourceWallet,
                $payingWallet,
                feesSubject.$value
            )
                .map { sourceWallet, payingWallet, fees in
                    calculateAvailableAmount(
                        sourceWallet: sourceWallet,
                        payingFeeWallet: payingWallet,
                        fees: fees
                    )
                }
                .assign(to: \.availableAmount, on: self)
                .store(in: &subscriptions)

            // auto fill balance after tapping max
            $availableAmount
                .filter { [weak self] availableAmount in
                    guard let self = self else { return false }
                    return self.isUsingAllBalance && self.inputAmount?
                        .rounded(decimals: self.sourceWallet?.token.decimals) > availableAmount?
                        .rounded(decimals: self.sourceWallet?.token.decimals)
                }
                .sink { [weak self] availableAmount in
                    self?.isUsingAllBalance = false
                    self?.enterInputAmount(availableAmount)
                }
                .store(in: &subscriptions)

            // get tradable pools pair for each token pair
            Publishers.CombineLatest(
                $sourceWallet.removeDuplicates(),
                $destinationWallet.removeDuplicates()
            )
                .sink { [weak self] sourceWallet, destinationWallet in
                    guard let self = self,
                          let sourceWallet = sourceWallet,
                          let destinationWallet = destinationWallet
                    else {
                        self?.tradablePoolsPairsSubject.request = { [] }
                        self?.tradablePoolsPairsSubject.reload()
                        return
                    }

                    self.tradablePoolsPairsSubject.request = { [weak self] in
                        try await self?.swapService.getPoolPair(
                            from: sourceWallet.token.address,
                            to: destinationWallet.token.address
                        ) ?? []
                    }
                    self.tradablePoolsPairsSubject.reload()
                }
                .store(in: &subscriptions)

            // Fill input amount and estimated amount after loaded
            tradablePoolsPairsSubject.$state
                .removeDuplicates()
                .filter { $0 == .loaded }
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    if let inputAmount = self.inputAmount,
                       self.activeInputField != .destination
                    {
                        self.enterInputAmount(inputAmount)
                    } else if let estimatedAmount = self.estimatedAmount {
                        self.enterEstimatedAmount(estimatedAmount)
                    }
                }
                .store(in: &subscriptions)

            // fees
            Observable.combineLatest(
                bestPoolsPairSubject,
                inputAmountSubject,
                slippageSubject,
                destinationWalletSubject,
                sourceWalletSubject,
                payingWalletSubject
            )
                .observe(on: MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.feesSubject.request = { [weak self] in
                        (try await self?.feesRequest()) ?? []
                    }
                    self.feesSubject.reload()
                })
                .store(in: &subscriptions)

            // Smart selection fee token paying

            // Input wallet was changed
            sourceWalletSubject
                .subscribe(onNext: { [weak self] wallet in
                    guard let self = self, let wallet = wallet else { return }
                    self.payingWallet = wallet)
                })
                .store(in: &subscriptions)

            // Input amount was changed
            inputAmountSubject
                .flatMap { Single.zip(.just($0), self.feesRequest()) }
                .subscribe(onNext: { [weak self] input, fees in
                    guard
                        let self = self,
                        let input = input,
                        let availableAmount = self.availableAmount
                    else { return }

                    // If paying token fee equals input token
                    if self.payingWallet == self.sourceWallet,
                       self.payingWallet?.isNativeSOL == false
                    {
                        // Selected wallet can not covert fee
                        if input + fees.totalDecimal > availableAmount,
                           self.walletsRepository.nativeWallet?.amount > 0
                        {
                            guard let solWallet = self.walletsRepository.nativeWallet else { return }
                            self.changeFeePayingToken(to: solWallet)
                        }
                    }
                })
                .store(in: &subscriptions)

            // Error
            Observable.combineLatest(
                loadingStateSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                tradablePoolsPairsSubject.stateObservable,
                bestPoolsPairSubject,
                feesObservable,
                slippageSubject,
                payingWalletSubject
            )
                .map { [weak self] _ in self?.verify() }
                .bind(to: errorSubject)
                .store(in: &subscriptions)

            showHideDetailsButtonTapSubject
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }

                    self.isShowingDetails = !self.isShowingDetails)
                })
                .store(in: &subscriptions)
        }

        func authenticateAndSwap() {
            authenticationHandler.authenticate(
                presentationStyle:
                .init(
                    completion: { [weak self] _ in
                        self?.swap()
                    }
                )
            )
        }

        func swap() {
            guard verify() == nil else { return }

            let authority = walletsRepository.nativeWallet?.pubkey
            let sourceWallet = sourceWallet!
            let destinationWallet = destinationWallet!
            let bestPoolsPair = bestPoolsPair!
            let inputAmount = inputAmount!
            let estimatedAmount = estimatedAmount!
            let payingWallet = payingWallet
            let slippage = slippage
            let fees = fees?.filter { $0.type != .liquidityProviderFee } ?? []

            let swapMAX = availableAmount == inputAmount

            // log
            minimumReceiveAmountObservable
                .first()
                .subscribe(onSuccess: { [weak self] receiveAmount in
                    guard let self = self else { return }

                    let receiveAmount: Double = receiveAmount.map { $0 ?? 0 } ?? 0
                    let receivePriceFiat: Double = destinationWallet.priceInCurrentFiat ?? 0.0
                    let swapUSD = receiveAmount * receivePriceFiat

                    // show processing scene
                    self.navigation =
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
                })
                .store(in: &subscriptions)
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
