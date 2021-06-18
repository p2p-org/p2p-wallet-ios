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
    let accountStorage: KeychainAccountStorage
    let analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: RestoreWalletViewModel
    
    init(
        accountStorage: KeychainAccountStorage,
        handler: CreateOrRestoreWalletHandler,
        analyticsManager: AnalyticsManagerType
    ) {
        self.viewModel = RestoreWalletViewModel(accountStorage: accountStorage, handler: handler, analyticsManager: analyticsManager)
        self.accountStorage = accountStorage
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
