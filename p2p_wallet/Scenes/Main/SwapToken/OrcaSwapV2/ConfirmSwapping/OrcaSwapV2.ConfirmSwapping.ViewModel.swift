//
//  OrcaSwapV2.ConfirmSwapping.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation

protocol OrcaSwapV2ConfirmSwappingViewModelType {
    func isBannerForceClosed() -> Bool
    
    func closeBanner()
}

extension OrcaSwapV2.ConfirmSwapping {
    final class ViewModel {
        
    }
}

extension OrcaSwapV2.ConfirmSwapping.ViewModel: OrcaSwapV2ConfirmSwappingViewModelType {
    func isBannerForceClosed() -> Bool {
        !Defaults.shouldShowConfirmAlertOnSwap
    }
    
    func closeBanner() {
        Defaults.shouldShowConfirmAlertOnSwap = false
    }
}
