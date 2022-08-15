//
//  OrcaSwapV2.ViewModel+Publishers.swift
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
        $navigation.eraseToAnyPublisher()
    }

    var loadingStatePublisher: AnyPublisher<LoadableState, Never> {
        $loadingState.eraseToAnyPublisher()
    }

    var sourceWalletPublisher: AnyPublisher<Wallet?, Never> {
        $sourceWallet.removeDuplicates().eraseToAnyPublisher()
    }

    var destinationWalletPublisher: AnyPublisher<Wallet?, Never> {
        $destinationWallet.removeDuplicates().eraseToAnyPublisher()
    }

    var inputAmountPublisher: AnyPublisher<Double?, Never> {
        $inputAmount.eraseToAnyPublisher()
    }

    var estimatedAmountPublisher: AnyPublisher<Double?, Never> {
        $estimatedAmount.eraseToAnyPublisher()
    }

    var feesPublisher: AnyPublisher<Loadable<[PayingFee]>, Never> {
        feesSubject.eraseToAnyPublisher()
    }

    var availableAmountPublisher: AnyPublisher<Double?, Never> {
        $availableAmount.eraseToAnyPublisher()
    }

    var slippagePublisher: AnyPublisher<Double, Never> {
        $slippage.eraseToAnyPublisher()
    }

    var minimumReceiveAmountPublisher: AnyPublisher<Double?, Never> {
        $bestPoolsPair
            .withLatestFrom(
                Publishers.CombineLatest4(
                    $inputAmount,
                    $slippage,
                    $sourceWallet,
                    $destinationWallet
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
            .eraseToAnyPublisher()
    }

    var exchangeRatePublisher: AnyPublisher<Double?, Never> {
        Publishers.CombineLatest(
            $inputAmount,
            $estimatedAmount
        )
            .map { inputAmount, estimatedAmount in
                guard let inputAmount = inputAmount,
                      let estimatedAmount = estimatedAmount,
                      inputAmount > 0,
                      estimatedAmount > 0
                else { return nil }
                return estimatedAmount / inputAmount
            }
            .eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<OrcaSwapV2.VerificationError?, Never> {
        $error.eraseToAnyPublisher()
    }

    var isSendingMaxAmountPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(availableAmountPublisher, inputAmountPublisher)
            .map { availableAmount, currentAmount in
                availableAmount == currentAmount
            }
            .eraseToAnyPublisher()
    }

    var isShowingDetailsPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            $isShowingDetails.eraseToAnyPublisher(),
            isShowingShowDetailsButtonPublisher
        )
            .map {
                $0 && $1
            }
            .eraseToAnyPublisher()
    }

    var isShowingShowDetailsButtonPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            $sourceWallet,
            $destinationWallet
        )
            .map {
                $0 != nil && $1 != nil
            }
            .eraseToAnyPublisher()
    }

    func getPrice(symbol: String) -> Double? {
        pricesService.currentPrice(for: symbol)?.value
    }

    // MARK: - Actions

    func reload() async {
        loadingState = .loading
        do {
            try await swapService.load()
            loadingState = .loaded
        } catch {
            loadingState = .error(error.readableDescription)
        }
    }

    func navigate(to scene: OrcaSwapV2.NavigatableScene) {
        navigation = scene
    }

    func chooseSourceWallet() {
        isSelectingSourceWallet = true
        analyticsManager.log(event: .tokenListViewed(lastScreen: "Swap", tokenListLocation: "Token_A"))
        navigation = .chooseSourceWallet(currentlySelectedWallet: sourceWallet)
    }

    func chooseDestinationWallet() {
        var destinationMints = [String]()
        if let sourceWallet = sourceWallet,
           let validMints = try? swapService.findPosibleDestinationMints(fromMint: sourceWallet.token.address)
        {
            destinationMints = validMints
        }
        isSelectingSourceWallet = false
        analyticsManager.log(event: .tokenListViewed(lastScreen: "Swap", tokenListLocation: "Token_B"))
        navigation = .chooseDestinationWallet(
            currentlySelectedWallet: destinationWallet,
            validMints: Set(destinationMints),
            excludedSourceWalletPubkey: sourceWallet?.pubkey
        )
    }

    func swapSourceAndDestination() {
        Swift.swap(&sourceWallet, &destinationWallet)
    }

    func setSlippage(_ slippage: Double) {
        self.slippage = slippage
    }

    func useAllBalance() {
        isUsingAllBalance = true
        enterInputAmount(availableAmount)

        if let fees = feesSubject.value, !fees.isEmpty, availableAmount != inputAmount {
            notificationsService
                .showInAppNotification(.message(L10n
                        .thisValueIsCalculatedBySubtractingTheTransactionFeeFromYourBalance))
        }
    }

    func enterInputAmount(_ amount: Double?) {
        let amount = amount?.rounded(decimals: sourceWallet?.token.decimals)
        inputAmount = amount

        // calculate estimated amount
        if let sourceDecimals = sourceWallet?.token.decimals,
           let destinationDecimals = destinationWallet?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = poolsPairs.findBestPoolsPairForInputAmount(inputAmount),
           let bestEstimatedAmount = bestPoolsPair.getOutputAmount(fromInputAmount: inputAmount)?
               .convertToBalance(decimals: destinationDecimals)
               .rounded(decimals: destinationDecimals)
        {
            estimatedAmount = bestEstimatedAmount
            self.bestPoolsPair = bestPoolsPair
        } else {
            estimatedAmount = nil
            bestPoolsPair = nil
        }
    }

    func enterEstimatedAmount(_ amount: Double?) {
        let amount = amount?.rounded(decimals: destinationWallet?.token.decimals)
        estimatedAmount = amount

        // calculate input amount
        if let sourceDecimals = sourceWallet?.token.decimals,
           let destinationDecimals = destinationWallet?.token.decimals,
           let estimatedAmount = amount?.toLamport(decimals: destinationDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = poolsPairs.findBestPoolsPairForEstimatedAmount(estimatedAmount),
           let bestInputAmount = bestPoolsPair.getInputAmount(fromEstimatedAmount: estimatedAmount)?
               .convertToBalance(decimals: sourceDecimals)
               .rounded(decimals: sourceDecimals)
        {
            inputAmount = bestInputAmount
            self.bestPoolsPair = bestPoolsPair
        } else {
            inputAmount = nil
            bestPoolsPair = nil
        }
    }

    func choosePayFee() {
        navigation = .settings
    }

    func openSettings() {
        navigate(to: .settings)
    }

    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapChangingTokenA(tokenAName: wallet.token.symbol))
            sourceWallet = wallet
        } else {
            analyticsManager.log(event: .swapChangingTokenB(tokenBName: wallet.token.symbol))
            destinationWallet = wallet
        }
    }

    var feePayingTokenPublisher: AnyPublisher<Wallet?, Never> {
        $payingWallet.eraseToAnyPublisher()
    }

    func changeFeePayingToken(to payingToken: Wallet) {
        payingWallet = payingToken
    }

    func cleanAllFields() {
        sourceWallet = nil
        destinationWallet = nil
        enterInputAmount(nil)
    }

    func showNotifications(_ message: String) {
        notificationsService.showInAppNotification(.message(message))
    }
}
