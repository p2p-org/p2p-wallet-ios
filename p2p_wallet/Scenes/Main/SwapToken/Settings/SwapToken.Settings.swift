//
//  SwapToken.Settings.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/08/2021.
//

import Foundation
import RxCocoa

extension SwapToken {
    // Forward to NewSwap, remove later
    typealias SettingsNavigationController = NewSwap.SettingsNavigationController
    typealias SettingsBaseViewController = NewSwap.SettingsBaseViewController
    typealias SettingsViewController = NewSwap.SettingsViewController
    typealias SlippageSettingsViewController = NewSwap.SlippageSettingsViewController
    typealias NetworkFeePayerSettingsViewController = NewSwap.NetworkFeePayerSettingsViewController
}

extension SwapToken.ViewModel: NewSwapSettingsViewModelType {
    var sourceWalletDriver: Driver<Wallet?> {
        output.sourceWallet
    }
    
    var destinationWalletDriver: Driver<Wallet?> {
        output.destinationWallet
    }
    
    var slippageDriver: Driver<Double?> {
        output.slippage.map(Optional.init)
    }
    
    func log(_ event: AnalyticsEvent) {
        analyticsManager.log(event: event)
    }
    
    func changeSlippage(to slippage: Double) {
        input.slippage.accept(slippage)
    }
}
