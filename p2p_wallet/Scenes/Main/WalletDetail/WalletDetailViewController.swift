//
//  WalletDetailViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import Foundation
import UIKit

protocol WalletDetailScenesFactory {
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> WLModalWrapperVC
    func makeSwapTokenViewController(fromWallet: Wallet?) -> SwapTokenViewController
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
}

class WalletDetailViewController: WLIndicatorModalVC {
    // MARK: - Properties
    let viewModel: WalletDetailViewModel
    let scenesFactory: WalletDetailScenesFactory
    
    // MARK: - Initializer
    init(viewModel: WalletDetailViewModel, scenesFactory: WalletDetailScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let rootView = WalletDetailRootView(viewModel: viewModel)
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: WalletDetailNavigatableScene) {
        switch scene {
        
        }
    }
}
