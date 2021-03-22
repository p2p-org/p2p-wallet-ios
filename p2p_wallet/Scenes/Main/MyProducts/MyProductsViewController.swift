//
//  MyProductsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation
import UIKit

class MyProductsViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: MyProductsViewModel
    let scenesFactory: MyWalletsScenesFactory
    lazy var rootView = MyProductsRootView(viewModel: viewModel)
    
    // MARK: - Initializer
    init(viewModel: MyProductsViewModel, scenesFactory: MyWalletsScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: MyProductsNavigatableScene) {
        switch scene {
        case .addNewWallet:
            let vc = scenesFactory.makeAddNewTokenVC()
            self.present(vc, animated: true, completion: nil)
        case .walletDetail(let pubkey, let symbol):
            let vc = scenesFactory.makeWalletDetailViewController(pubkey: pubkey, symbol: symbol)
            self.present(vc, animated: true, completion: nil)
        case .walletSettings(let wallet):
            guard let pubkey = wallet.pubkey else {return}
            let vc = self.scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
            self.present(vc, animated: true, completion: nil)
        }
    }
}
