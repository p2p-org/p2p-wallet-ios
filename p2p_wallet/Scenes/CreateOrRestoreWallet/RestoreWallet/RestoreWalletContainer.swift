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
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // longlived dependency
    let viewModel: RestoreWalletViewModel
    
    init(
        handler: CreateOrRestoreWalletHandler
    ) {
        self.viewModel = RestoreWalletViewModel(handler: handler)
        self.handler = handler
    }
    
    func makeRestoreWalletViewController() -> RestoreWalletViewController
    {
        RestoreWalletViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeEnterPhrasesVC() -> RecoveryEnterSeedsViewController {
        RecoveryEnterSeedsViewController(handler: viewModel)
    }
    
    func makeDerivableAccountsVC(phrases: [String]) -> DerivableAccountsVC {
        let viewModel = DerivableAccountsViewModel(
            phrases: phrases,
            pricesFetcher: CryptoComparePricesFetcher(),
            handler: viewModel
        )
        return DerivableAccountsVC(viewModel: viewModel)
    }
}

extension RestoreWalletContainer: RestoreWalletScenesFactory {}
