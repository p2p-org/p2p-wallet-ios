//
//  OrcaSwapV2ViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/10/2021.
//

import Foundation
import RxCocoa

protocol OrcaSwapV2ViewModelType: WalletDidSelectHandler, AnyObject {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {get}
    var loadingStateDriver: Driver<LoadableState> {get}
    
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var inputAmountDriver: Driver<Double?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    var availableAmountDriver: Driver<Double?> {get}
    var minimumReceiveAmountDriver: Driver<Double?> {get}
    var slippageDriver: Driver<Double> {get}
    var exchangeRateDriver: Driver<Double?> {get}
    
    var feesDriver: Driver<Loadable<[PayingFee]>> {get}
    var feePayingTokenDriver: Driver<Wallet?> {get}
    var errorDriver: Driver<OrcaSwapV2.VerificationError?> {get}
    var isSendingMaxAmountDriver: Driver<Bool> { get }
    var isShowingDetailsDriver: Driver<Bool> { get }
    var isShowingShowDetailsButtonDriver: Driver<Bool> { get }
    var showHideDetailsButtonTapSubject: PublishRelay<Void> { get }
    var slippageSubject: BehaviorRelay<Double> { get }

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
    func changeFeePayingToken(to payingToken: Wallet)
    func choosePayFee()
    func openSettings()
    
    func cleanAllFields()
    
    func authenticateAndSwap()
}

extension OrcaSwapV2ViewModelType {
    var feePayingTokenStringDriver: Driver<String?> {
        feePayingTokenDriver.map { wallet in wallet?.token.symbol }
    }
}
