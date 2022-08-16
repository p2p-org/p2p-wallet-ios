//
//  OrcaSwapV2.ConfirmSwapping.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Combine
import Foundation
import Resolver
import SolanaSwift

extension OrcaSwapV2.ConfirmSwapping {
    final class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var pricesService: PricesServiceType

        // MARK: - Properties

        private let swapViewModel: OrcaSwapV2ViewModelType

        // MARK: - Initializers

        init(swapViewModel: OrcaSwapV2ViewModelType) {
            self.swapViewModel = swapViewModel
            super.init()
        }
    }
}

extension OrcaSwapV2.ConfirmSwapping.ViewModel: OrcaSwapV2ConfirmSwappingViewModelType {
    var sourceWalletPublisher: AnyPublisher<Wallet?, Never> {
        swapViewModel.sourceWalletPublisher
    }

    var destinationWalletPublisher: AnyPublisher<Wallet?, Never> {
        swapViewModel.destinationWalletPublisher
    }

    var inputAmountPublisher: AnyPublisher<Double?, Never> {
        swapViewModel.inputAmountPublisher
    }

    var estimatedAmountPublisher: AnyPublisher<Double?, Never> {
        swapViewModel.estimatedAmountPublisher
    }

    var minimumReceiveAmountPublisher: AnyPublisher<Double?, Never> {
        swapViewModel.minimumReceiveAmountPublisher
    }

    var exchangeRatesPublisher: AnyPublisher<Double?, Never> {
        swapViewModel.exchangeRatePublisher
    }

    var feesPublisher: AnyPublisher<Loadable<[PayingFee]>, Never> {
        swapViewModel.feesPublisher
    }

    var slippagePublisher: AnyPublisher<Double, Never> {
        swapViewModel.slippagePublisher
    }

    func isBannerForceClosed() -> Bool {
        !Defaults.shouldShowConfirmAlertOnSwap
    }

    func getPrice(symbol: String) -> Double? {
        pricesService.currentPrice(for: symbol)?.value
    }

    func closeBanner() {
        Defaults.shouldShowConfirmAlertOnSwap = false
    }

    func authenticateAndSwap() {
        swapViewModel.authenticateAndSwap()
    }

    func showFeesInfo(_ info: PayingFee.Info) {
        swapViewModel.navigate(to: .info(title: info.alertTitle, description: info.alertDescription))
    }
}
