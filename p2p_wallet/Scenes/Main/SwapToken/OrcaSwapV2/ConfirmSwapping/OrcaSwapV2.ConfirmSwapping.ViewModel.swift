//
//  OrcaSwapV2.ConfirmSwapping.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation
import Resolver
import RxCocoa
import SolanaSwift

extension OrcaSwapV2.ConfirmSwapping {
    final class ViewModel {
        // MARK: - Dependencies

        @Injected private var analyticsService: AnalyticsService
        @Injected private var pricesService: PricesServiceType

        // MARK: - Properties

        private let swapViewModel: OrcaSwapV2ViewModelType

        // MARK: - Initializers

        init(swapViewModel: OrcaSwapV2ViewModelType) {
            self.swapViewModel = swapViewModel
        }
    }
}

extension OrcaSwapV2.ConfirmSwapping.ViewModel: OrcaSwapV2ConfirmSwappingViewModelType {
    var sourceWalletDriver: Driver<Wallet?> {
        swapViewModel.sourceWalletDriver
    }

    var destinationWalletDriver: Driver<Wallet?> {
        swapViewModel.destinationWalletDriver
    }

    var inputAmountDriver: Driver<Double?> {
        swapViewModel.inputAmountDriver
    }

    var estimatedAmountDriver: Driver<Double?> {
        swapViewModel.estimatedAmountDriver
    }

    var minimumReceiveAmountDriver: Driver<Double?> {
        swapViewModel.minimumReceiveAmountDriver
    }

    var exchangeRatesDriver: Driver<Double?> {
        swapViewModel.exchangeRateDriver
    }

    var feesDriver: Driver<Loadable<[PayingFee]>> {
        swapViewModel.feesDriver
    }

    var slippageDriver: Driver<Double> {
        swapViewModel.slippageDriver
    }

    func isBannerForceClosed() -> Bool {
        !Defaults.shouldShowConfirmAlertOnSwap
    }

    func getPrice(mint: String) -> Double? {
        pricesService.currentPrice(mint: mint)?.value
    }

    func closeBanner() {
        Defaults.shouldShowConfirmAlertOnSwap = false
    }

    func authenticateAndSwap() {
        swapViewModel.authenticateAndSwap()
        analyticsService.logEvent(.swapClickApproveButton)
    }

    func showFeesInfo(_ info: PayingFee.Info) {
        swapViewModel.navigate(to: .info(title: info.alertTitle, description: info.alertDescription))
    }
}
