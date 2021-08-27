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
    typealias SwapFeesViewController = NewSwap.SwapFeesViewController
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

extension SwapToken.ViewModel: NewSwapSwapFeesViewModelType {
    var feesDriver: Driver<[FeeType: SwapFee]> {
        Driver.combineLatest(
            output.feeInLamports,
            output.liquidityProviderFee,
            output.sourceWallet,
            output.destinationWallet
        )
            .map {fee, liquidityProviderFee, source, destination -> [FeeType: SwapFee] in
                var result = [FeeType: SwapFee]()
                guard let source = source, let destination = destination
                else {return result}
                
                if let fee = liquidityProviderFee {
                    result[.liquidityProvider] = .init(
                        lamports: fee.toLamport(decimals: destination.token.decimals),
                        token: destination.token
                    )
                }
                
                if let fee = fee {
                    if SwapToken.isFeeRelayerEnabled(source: source, destination: destination) {
                        result[.default] = .init(
                            lamports: fee,
                            token: source.token
                        )
                    } else {
                        result[.default] = .init(
                            lamports: fee,
                            token: .nativeSolana
                        )
                    }
                }
                
                return result
            }
    }
}
