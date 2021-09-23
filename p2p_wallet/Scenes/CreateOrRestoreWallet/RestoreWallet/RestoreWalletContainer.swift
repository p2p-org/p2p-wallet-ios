//
//  RestoreWalletContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class RestoreWalletContainer {
    // from parent
    let handler: CreateOrRestoreWalletHandler
    @Injected private var accountStorage: KeychainAccountStorage
    let analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: RestoreWalletViewModel
    
    init(
        handler: CreateOrRestoreWalletHandler,
        analyticsManager: AnalyticsManagerType
    ) {
        self.viewModel = RestoreWalletViewModel(handler: handler, analyticsManager: analyticsManager)
        self.handler = handler
        self.analyticsManager = analyticsManager
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        RestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeEnterPhrasesVC() -> RecoveryEnterSeedsViewController {
        RecoveryEnterSeedsViewController(handler: viewModel, analyticsManager: analyticsManager)
    }
    
    func makeDerivableAccountsVC(phrases: [String]) -> DerivableAccountsVC {
        let viewModel = DerivableAccountsViewModel(
            phrases: phrases,
            pricesFetcher: CryptoComparePricesFetcher(),
            handler: viewModel
        )
        return DerivableAccountsVC(viewModel: viewModel, analyticsManager: analyticsManager)
    }
}

extension RestoreWalletContainer: RestoreWalletScenesFactory {}
