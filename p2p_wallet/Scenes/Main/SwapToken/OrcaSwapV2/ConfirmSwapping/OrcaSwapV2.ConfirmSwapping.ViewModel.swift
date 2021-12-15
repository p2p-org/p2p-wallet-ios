//
//  OrcaSwapV2.ConfirmSwapping.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation
import RxCocoa

protocol OrcaSwapV2ConfirmSwappingViewModelType {
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var inputAmountDriver: Driver<Double?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    var minimumReceiveAmountDriver: Driver<Double?> {get}
    var exchangeRatesDriver: Driver<Double?> {get}
    var feesDriver: Driver<Loadable<[PayingFee]>> {get}
    
    func isBannerForceClosed() -> Bool
    
    func closeBanner()
}

extension OrcaSwapV2.ConfirmSwapping {
    final class ViewModel {
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
    
    func isBannerForceClosed() -> Bool {
        !Defaults.shouldShowConfirmAlertOnSwap
    }
    
    func closeBanner() {
        Defaults.shouldShowConfirmAlertOnSwap = false
    }
}
