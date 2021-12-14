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
    
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {
        tradablePoolsPairsSubject.asDriver()
            .map { value, state, reloadAction in
                (value?.isEmpty == false, state, reloadAction)
            }
    }
    
    var bestPoolsPairDriver: Driver<OrcaSwap.PoolsPair?> {
        bestPoolsPairSubject.asDriver()
    }
    
    var inputAmountDriver: Driver<Double?> {
        inputAmountSubject.asDriver()
    }
    
    var estimatedAmountDriver: Driver<Double?> {
        estimatedAmountSubject.asDriver()
    }
    
    var feesContentDriver: Driver<Loadable<OrcaSwapV2.DetailedFeesContent>> {
        feesSubject.asDriver()
            .map { [weak self] value, state, reload in
                (
                    value: value.flatMap {
                        self?.createFeesDetailedContent(fees: $0)
                    },
                    state: state,
                    reloadAction: reload
                )
            }
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
                return poolsPair.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)?.convertToBalance(decimals: destinationDecimals)
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
        payingTokenSubject.asDriver()
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
            orcaSwap.load(),
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
        navigationSubject.accept(.chooseSourceWallet)
    }
    
    func chooseDestinationWallet() {
        var destinationMints = [String]()
        if let sourceWallet = sourceWalletSubject.value,
           let validMints = try? orcaSwap.findPosibleDestinationMints(fromMint: sourceWallet.token.address)
        {
            destinationMints = validMints
        }
        isSelectingSourceWallet = false
        navigationSubject.accept(.chooseDestinationWallet(validMints: Set(destinationMints), excludedSourceWalletPubkey: sourceWalletSubject.value?.pubkey))
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

        // fees depends on input amount, so after entering availableAmount, fees has changed, so needed to calculate availableAmount again
        let availableAmountUpdated = calculateAvailableAmount()
        enterInputAmount(availableAmountUpdated)
    }
    
    func enterInputAmount(_ amount: Double?) {
        inputAmountSubject.accept(amount)

        // calculate estimated amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs),
           let bestEstimatedAmount = bestPoolsPair.getOutputAmount(fromInputAmount: inputAmount)
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
           let bestPoolsPair = try? orcaSwap.findBestPoolsPairForEstimatedAmount(estimatedAmount, from: poolsPairs),
           let bestInputAmount = bestPoolsPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
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
        navigationSubject.accept(.choosePayFeeToken(tokenName: transactionTokensName))
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

extension OrcaSwapV2.ViewModel {
    private func createFeesDetailedContent(fees: [PayingFee]) -> OrcaSwapV2.DetailedFeesContent {
        let totalFeeString: String? = fees.totalFee.map { totalFee in
            let totalDouble = totalFee.lamports.convertToBalance(decimals: totalFee.token.decimals)
            return totalDouble.toString(maximumFractionDigits: 9) + " " + totalFee.token.symbol
        }

        return .init(
            parts: fees.compactMap(feeToString),
            total: totalFeeString
        )
    }
    
    private func feeToString(fee: PayingFee) -> OrcaSwapV2.DetailedFeeContent? {
        if let toString = fee.toString {
            return toString().map {
                OrcaSwapV2.DetailedFeeContent(
                    amount: $0,
                    reason: fee.headerString
                )
            }
        }

        let amount = fee.lamports.convertToBalance(decimals: fee.token.decimals)
        let symbol = fee.token.symbol

        return .init(
            amount: amount.toString(maximumFractionDigits: 9) + " " + symbol,
            reason: fee.headerString
        )
    }
}
