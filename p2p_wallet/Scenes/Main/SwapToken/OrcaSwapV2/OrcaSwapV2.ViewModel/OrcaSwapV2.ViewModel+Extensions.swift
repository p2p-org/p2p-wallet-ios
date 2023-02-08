//
//  OrcaSwapV2.ViewModel+Drivers.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2021.
//

import AnalyticsManager
import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

extension OrcaSwapV2.ViewModel: OrcaSwapV2ViewModelType {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var loadingStateDriver: Driver<LoadableState> {
        loadingStateSubject.asDriver()
    }

    var sourceWalletDriver: Driver<Wallet?> {
        sourceWalletSubject.asDriver().distinctUntilChanged()
    }

    var destinationWalletDriver: Driver<Wallet?> {
        destinationWalletSubject.asDriver().distinctUntilChanged()
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
        availableAmountSubject.asDriver()
    }

    var slippageDriver: Driver<Double> {
        slippageSubject.asDriver()
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

    var minimumReceiveAmountDriver: Driver<Double?> {
        minimumReceiveAmountObservable.asDriver(onErrorJustReturn: nil)
    }

    var exchangeRateDriver: Driver<Double?> {
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

    var errorDriver: Driver<OrcaSwapV2.VerificationError?> {
        errorSubject.asDriver()
    }

    var isSendingMaxAmountDriver: Driver<Bool> {
        Driver.combineLatest(availableAmountDriver, inputAmountDriver)
            .map { availableAmount, currentAmount in
                availableAmount == currentAmount
            }
    }

    var isShowingDetailsDriver: Driver<Bool> {
        Driver.combineLatest(
            isShowingDetailsSubject.asDriver(),
            isShowingShowDetailsButtonDriver
        )
            .map {
                $0 && $1
            }
    }

    var isShowingShowDetailsButtonDriver: Driver<Bool> {
        Driver.combineLatest(
            sourceWalletDriver,
            destinationWalletDriver
        )
            .map {
                $0 != nil && $1 != nil
            }
    }
    
    #if !RELEASE
    var routeDriver: Driver<String?> {
        bestPoolsPairSubject
            .map { bestPoolsPair -> String? in
                guard let bestPoolsPair = bestPoolsPair,
                      !bestPoolsPair.isEmpty,
                      bestPoolsPair.count <= 2
                else {
                    return nil
                }
                var route = bestPoolsPair[0].tokenAName + " -> " + bestPoolsPair[0].tokenBName
                if bestPoolsPair.count == 2 {
                    route += " -> " + bestPoolsPair[1].tokenBName
                }
                return route
            }
            .asDriver()
    }
    #endif

    func getPrice(mint: String) -> Double? {
        pricesService.currentPrice(mint: mint)?.value
    }

    // MARK: - Actions

    func reload() {
        loadingStateSubject.accept(.loading)

        Completable.async { [unowned self] in try await swapService.reload() }
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
           let bestPoolsPair = try? swapService.findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs),
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
           let bestPoolsPair = try? swapService.findBestPoolsPairForEstimatedAmount(estimatedAmount, from: poolsPairs),
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
            analyticsManager.log(event: .swapChangingTokenA(tokenA_Name: wallet.token.symbol))
            sourceWalletSubject.accept(wallet)
        } else {
            analyticsManager.log(event: .swapChangingTokenB(tokenB_Name: wallet.token.symbol))
            destinationWalletSubject.accept(wallet)
        }
    }

    var feePayingTokenDriver: Driver<Wallet?> {
        payingWalletSubject.asDriver()
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
