//
//  OrcaSwapV2ViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/10/2021.
//

import Combine
import Foundation
import SolanaSwift

protocol OrcaSwapV2ViewModelType: WalletDidSelectHandler, AnyObject, DetailFeesViewModelType {
    var navigatableScenePublisher: AnyPublisher<OrcaSwapV2.NavigatableScene?, Never> { get }
    var loadingStatePublisher: AnyPublisher<LoadableState, Never> { get }

    var sourceWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    var destinationWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    var inputAmountPublisher: AnyPublisher<Double?, Never> { get }
    var estimatedAmountPublisher: AnyPublisher<Double?, Never> { get }
    var minimumReceiveAmountPublisher: AnyPublisher<Double?, Never> { get }
    var slippagePublisher: AnyPublisher<Double, Never> { get }
    var exchangeRatePublisher: AnyPublisher<Double?, Never> { get }

    var feePayingTokenPublisher: AnyPublisher<Wallet?, Never> { get }
    var errorPublisher: AnyPublisher<OrcaSwapV2.VerificationError?, Never> { get }
    var isSendingMaxAmountPublisher: AnyPublisher<Bool, Never> { get }
    var isShowingDetailsPublisher: AnyPublisher<Bool, Never> { get }
    var isShowingShowDetailsButtonPublisher: AnyPublisher<Bool, Never> { get }
    var showHideDetailsButtonTapSubject: PassthroughSubject<Void, Never> { get }
    #if !RELEASE
    var routePublisher: AnyPublisher<String?, Never> { get }
    #endif
    var activeInputField: OrcaSwapV2.ActiveInputField { get set }
    var slippage: Double { get }

    func reload() async
    func navigate(to scene: OrcaSwapV2.NavigatableScene)
    func chooseSourceWallet()
    func chooseDestinationWallet()
    func swapSourceAndDestination()
    func setSlippage(_ slippage: Double)
    func useAllBalance()
    func enterInputAmount(_ amount: Double?)
    func enterEstimatedAmount(_ amount: Double?)
    func changeFeePayingToken(to payingToken: Wallet)
    func choosePayFee()
    func openSettings()

    func cleanAllFields()
    func showNotifications(_ message: String)

    func authenticateAndSwap()
}

extension OrcaSwapV2ViewModelType {
    var feePayingTokenStringPublisher: AnyPublisher<String?, Never> {
        feePayingTokenPublisher
            .map { wallet in wallet?.token.symbol }
            .eraseToAnyPublisher()
    }
}
