//
//  OrcaSwapV2ViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/10/2021.
//

import Foundation
import RxCocoa

protocol OrcaSwapV2ViewModelType: WalletDidSelectHandler, SwapTokenSettingsViewModelType,
    AnyObject
{
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {get}
    var loadingStateDriver: Driver<LoadableState> {get}
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {get}
    var bestPoolsPairDriver: Driver<OrcaSwap.PoolsPair?> {get}
    var inputAmountDriver: Driver<Double?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    var feesContentDriver: Driver<Loadable<OrcaSwapV2.DetailedFeesContent>> { get }
    var feesDriver: Driver<Loadable<[PayingFee]>> {get}
    var availableAmountDriver: Driver<Double?> {get}
    var slippageDriver: Driver<Double> {get}
    var minimumReceiveAmountDriver: Driver<Double?> {get}
    var exchangeRateDriver: Driver<Double?> {get}
    var feePayingTokenDriver: Driver<String?> { get }
    var payingTokenDriver: Driver<PayingToken> {get}
    var errorDriver: Driver<OrcaSwapV2.VerificationError?> {get}
    var isSendingMaxAmountDriver: Driver<Bool> { get }
    var isShowingDetailsDriver: Driver<Bool> { get }
    var isShowingShowDetailsButtonDriver: Driver<Bool> { get }
    var showHideDetailsButtonTapSubject: PublishRelay<Void> { get }

    func reload()
    func log(_ event: AnalyticsEvent)
    func navigate(to scene: OrcaSwapV2.NavigatableScene)
    func chooseSourceWallet()
    func chooseDestinationWallet()
    func retryLoadingRoutes()
    func swapSourceAndDestination()
    func useAllBalance()
    func enterInputAmount(_ amount: Double?)
    func enterEstimatedAmount(_ amount: Double?)
    func changeSlippage(to slippage: Double)
    func changePayingToken(to payingToken: PayingToken)
    func choosePayFee()
    
    func authenticateAndSwap()
}
