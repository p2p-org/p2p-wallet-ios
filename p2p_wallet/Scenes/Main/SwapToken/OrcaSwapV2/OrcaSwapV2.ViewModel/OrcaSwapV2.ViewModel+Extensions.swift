//
//  OrcaSwapV2.ViewModel+Drivers.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2021.
//

import Foundation
import RxSwift
import RxCocoa

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
                return poolsPair.orcaPoolPair.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)?.convertToBalance(decimals: destinationDecimals)
            }
            .asDriver(onErrorJustReturn: nil)
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
    
    var feePayingTokenDriver: Driver<String?> {
        Driver.combineLatest(
            sourceWalletDriver,
            destinationWalletDriver,
            payingTokenDriver
        )
            .map { source, destination, payingToken in
                var symbols = [String]()
                if let source = source {symbols.append(source.token.symbol)}
                if let destination = destination {symbols.append(destination.token.symbol)}

                let transactionTokensName = symbols.isEmpty ? nil: symbols.joined(separator: "+")

                let text: String
                // if source or destination is native wallet
                if source == nil && destination == nil {
                    text = payingToken == .nativeSOL ? "SOL": L10n.transactionToken
                } else if
                    source?.isNativeSOL == true
                    || destination?.isNativeSOL == true
                    || payingToken == .nativeSOL
                {
                    text = "SOL"
                } else {
                    text = transactionTokensName ?? L10n.transactionToken
                }

                return text
            }
    }
    
    var payingTokenDriver: Driver<PayingToken> {
        payingTokenModeSubject.asDriver()
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
    
    // MARK: - Actions
    func reload() {
        loadingStateSubject.accept(.loading)

        Completable.zip(
            feeService.load()
        )
            .subscribe(onCompleted: {[weak self] in
                self?.loadingStateSubject.accept(.loaded)
            }, onError: {[weak self] error in
                self?.loadingStateSubject.accept(.error(error.readableDescription))
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
        navigationSubject.accept(.chooseSourceWallet(currentlySelectedWallet: sourceWalletSubject.value))
    }
    
    func chooseDestinationWallet() {
        var destinationMints = [String]()
        if let sourceWallet = sourceWalletSubject.value,
           let validMints = try? swapService.findPosibleDestinationMints(fromMint: sourceWallet.token.address) {
            destinationMints = validMints
        }
        isSelectingSourceWallet = false
        navigationSubject.accept(.chooseDestinationWallet(currentlySelectedWallet: destinationWalletSubject.value, validMints: Set(destinationMints), excludedSourceWalletPubkey: sourceWalletSubject.value?.pubkey))
    }
    
    func retryLoadingRoutes() {
        tradablePoolsPairsSubject.reload()
    }
    
    func swapSourceAndDestination() {
        let source = sourceWalletSubject.value
        sourceWalletSubject.accept(destinationWalletSubject.value)
        destinationWalletSubject.accept(source)
    }
    
    func useAllBalance() {
        let availableAmount = calculateAvailableAmount()
        enterInputAmount(availableAmount)

        // fees depends on input amount, so after entering availableAmount, fees has changed, so needed to calculate availableAmount again with 300 milliseconds of debouncing
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
            guard let self = self else {return}
            let availableAmountUpdated = self.calculateAvailableAmount()
            self.enterInputAmount(availableAmountUpdated)
        }
    }
    
    func enterInputAmount(_ amount: Double?) {
        inputAmountSubject.accept(amount)

        // calculate estimated amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = poolsPairs.findBestPoolsPairForInputAmount(inputAmount),
           let bestEstimatedAmount = bestPoolsPair.orcaPoolPair.getOutputAmount(fromInputAmount: inputAmount)
        {
            estimatedAmountSubject.accept(bestEstimatedAmount.convertToBalance(decimals: destinationDecimals))
            bestPoolsPairSubject.accept(bestPoolsPair)
        } else {
            estimatedAmountSubject.accept(nil)
            bestPoolsPairSubject.accept(nil)
        }
    }

    func enterEstimatedAmount(_ amount: Double?) {
        estimatedAmountSubject.accept(amount)

        // calculate input amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let estimatedAmount = amount?.toLamport(decimals: destinationDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = poolsPairs.findBestPoolsPairForEstimatedAmount(estimatedAmount),
           let bestInputAmount = bestPoolsPair.orcaPoolPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
        {
            inputAmountSubject.accept(bestInputAmount.convertToBalance(decimals: sourceDecimals))
            bestPoolsPairSubject.accept(bestPoolsPair)
        } else {
            inputAmountSubject.accept(nil)
            bestPoolsPairSubject.accept(nil)
        }
    }
    
    func changeSlippage(to slippage: Double) {
        Defaults.slippage = slippage
        slippageSubject.accept(slippage)
    }

    func changePayingToken(to payingToken: PayingToken) {
        Defaults.payingToken = payingToken
        fixPayingToken()
    }
    
    func choosePayFee() {
        navigationSubject.accept(.settings)
    }

    func openSettings() {
        navigate(to: .settings)
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
}
