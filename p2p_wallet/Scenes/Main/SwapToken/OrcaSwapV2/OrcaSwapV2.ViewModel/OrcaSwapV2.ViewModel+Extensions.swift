//
//  OrcaSwapV2.ViewModel+Drivers.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2021.
//

import AnalyticsManager
import Combine
import Foundation
import SolanaSwift

extension OrcaSwapV2.ViewModel: OrcaSwapV2ViewModelType {
    var navigationPublisher: AnyPublisher<OrcaSwapV2.NavigatableScene?, Never> {
        navigationSubject.eraseToAnyPublisher()
    }

    var loadingStatePublisher: AnyPublisher<LoadableState, Never> {
        loadingStateSubject.eraseToAnyPublisher()
    }

    var sourceWalletPublisher: AnyPublisher<Wallet?, Never> {
        sourceWalletSubject.eraseToAnyPublisher().distinctUntilChanged()
    }

    var destinationWalletPublisher: AnyPublisher<Wallet?, Never> {
        destinationWalletSubject.eraseToAnyPublisher().distinctUntilChanged()
    }

    var inputAmountPublisher: AnyPublisher<Double?, Never> {
        inputAmountSubject.eraseToAnyPublisher()
    }

    var estimatedAmountPublisher: AnyPublisher<Double?, Never> {
        estimatedAmountSubject.eraseToAnyPublisher()
    }

    var feesPublisher: AnyPublisher<Loadable<[PayingFee]>, Never> {
        feesSubject.eraseToAnyPublisher()
    }

    var availableAmountPublisher: AnyPublisher<Double?, Never> {
        availableAmountSubject.eraseToAnyPublisher()
    }

    var slippagePublisher: AnyPublisher<Double, Never> {
        slippageSubject.eraseToAnyPublisher()
    }

    var minimumReceiveAmountObservable: Observable<Double?> {
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
                else { return nil }
                return poolsPair.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)?
                    .convertToBalance(decimals: destinationDecimals)
            }
    }

    var minimumReceiveAmountPublisher: AnyPublisher<Double?, Never> {
        minimumReceiveAmountObservable.asDriver(onErrorJustReturn: nil)
    }

    var exchangeRatePublisher: AnyPublisher<Double?, Never> {
        Observable.combineLatest(
            inputAmountSubject,
            estimatedAmountSubject
        )
            .map { inputAmount, estimatedAmount in
                guard let inputAmount = inputAmount,
                      let estimatedAmount = estimatedAmount,
                      inputAmount > 0,
                      estimatedAmount > 0
                else { return nil }
                return estimatedAmount / inputAmount
            }
            .asDriver(onErrorJustReturn: nil)
    }

    var errorPublisher: AnyPublisher<OrcaSwapV2.VerificationError?, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var isSendingMaxAmountPublisher: AnyPublisher<Bool, Never> {
        Driver.combineLatest(availableAmountDriver, inputAmountDriver)
            .map { availableAmount, currentAmount in
                availableAmount == currentAmount
            }
    }

    var isShowingDetailsPublisher: AnyPublisher<Bool, Never> {
        Driver.combineLatest(
            isShowingDetailsSubject.eraseToAnyPublisher(),
            isShowingShowDetailsButtonDriver
        )
            .map {
                $0 && $1
            }
    }

    var isShowingShowDetailsButtonPublisher: AnyPublisher<Bool, Never> {
        Driver.combineLatest(
            sourceWalletDriver,
            destinationWalletDriver
        )
            .map {
                $0 != nil && $1 != nil
            }
    }

    func getPrice(symbol: String) -> Double? {
        pricesService.currentPrice(for: symbol)?.value
    }

    // MARK: - Actions

    func reload() {
        loadingStateSubject.accept(.loading)

        Completable.async { try await self.swapService.load() }
            .subscribe(
                onCompleted: { [weak self] in
                    self?.loadingStateSubject.accept(.loaded)
                },
                onError: { [weak self] error in
                    self?.loadingStateSubject.accept(.error(error.readableDescription))
                }
            )
            .disposed(by: disposeBag)
    }

    func navigate(to scene: OrcaSwapV2.NavigatableScene) {
        navigationSubject.accept(scene)
    }

    func chooseSourceWallet() {
        isSelectingSourceWallet = true
        analyticsManager.log(event: .tokenListViewed(lastScreen: "Swap", tokenListLocation: "Token_A"))
        navigationSubject.accept(.chooseSourceWallet(currentlySelectedWallet: sourceWalletSubject.value))
    }

    func chooseDestinationWallet() {
        var destinationMints = [String]()
        if let sourceWallet = sourceWalletSubject.value,
           let validMints = try? swapService.findPosibleDestinationMints(fromMint: sourceWallet.token.address)
        {
            destinationMints = validMints
        }
        isSelectingSourceWallet = false
        analyticsManager.log(event: .tokenListViewed(lastScreen: "Swap", tokenListLocation: "Token_B"))
        navigationSubject.accept(.chooseDestinationWallet(
            currentlySelectedWallet: destinationWalletSubject.value,
            validMints: Set(destinationMints),
            excludedSourceWalletPubkey: sourceWalletSubject.value?.pubkey
        ))
    }

    func swapSourceAndDestination() {
        let source = sourceWalletSubject.value
        sourceWalletSubject.accept(destinationWalletSubject.value)
        destinationWalletSubject.accept(source)
    }

    func useAllBalance() {
        isUsingAllBalance = true
        enterInputAmount(availableAmountSubject.value)

        if let fees = feesSubject.value, !fees.isEmpty, availableAmountSubject.value != inputAmountSubject.value {
            notificationsService
                .showInAppNotification(.message(L10n
                        .thisValueIsCalculatedBySubtractingTheTransactionFeeFromYourBalance))
        }
    }

    func enterInputAmount(_ amount: Double?) {
        let amount = amount?.rounded(decimals: sourceWalletSubject.value?.token.decimals)
        inputAmountSubject.accept(amount)

        // calculate estimated amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = poolsPairs.findBestPoolsPairForInputAmount(inputAmount),
           let bestEstimatedAmount = bestPoolsPair.getOutputAmount(fromInputAmount: inputAmount)?
               .convertToBalance(decimals: destinationDecimals)
               .rounded(decimals: destinationDecimals)
        {
            estimatedAmountSubject.accept(bestEstimatedAmount)
            bestPoolsPairSubject.accept(bestPoolsPair)
        } else {
            estimatedAmountSubject.accept(nil)
            bestPoolsPairSubject.accept(nil)
        }
    }

    func enterEstimatedAmount(_ amount: Double?) {
        let amount = amount?.rounded(decimals: destinationWalletSubject.value?.token.decimals)
        estimatedAmountSubject.accept(amount)

        // calculate input amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let estimatedAmount = amount?.toLamport(decimals: destinationDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = poolsPairs.findBestPoolsPairForEstimatedAmount(estimatedAmount),
           let bestInputAmount = bestPoolsPair.getInputAmount(fromEstimatedAmount: estimatedAmount)?
               .convertToBalance(decimals: sourceDecimals)
               .rounded(decimals: sourceDecimals)
        {
            inputAmountSubject.accept(bestInputAmount)
            bestPoolsPairSubject.accept(bestPoolsPair)
        } else {
            inputAmountSubject.accept(nil)
            bestPoolsPairSubject.accept(nil)
        }
    }

    func choosePayFee() {
        navigationSubject.accept(.settings)
    }

    func openSettings() {
        navigate(to: .settings)
    }

    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapChangingTokenA(tokenAName: wallet.token.symbol))
            sourceWalletSubject.accept(wallet)
        } else {
            analyticsManager.log(event: .swapChangingTokenB(tokenBName: wallet.token.symbol))
            destinationWalletSubject.accept(wallet)
        }
    }

    var feePayingTokenPublisher: AnyPublisher<Wallet?, Never> {
        payingWalletSubject.eraseToAnyPublisher()
    }

    func changeFeePayingToken(to payingToken: Wallet) {
        payingWalletSubject.accept(payingToken)
    }

    func cleanAllFields() {
        sourceWalletSubject.accept(nil)
        destinationWalletSubject.accept(nil)
        enterInputAmount(nil)
    }

    func showNotifications(_ message: String) {
        notificationsService.showInAppNotification(.message(message))
    }
}
