//
//  WalletDetailViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import Foundation
import UIKit

protocol WalletDetailScenesFactory {
    func makeReceiveTokenViewController(pubkey: String?) -> ReceiveTokenViewController
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> SendTokenViewController
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
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: WalletDetailNavigatableScene) {
        switch scene {
        case .settings:
            let vc = scenesFactory.makeTokenSettingsViewController(pubkey: viewModel.pubkey)
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        case .send:
            guard let wallet = viewModel.wallet.value else {return}
            let vc = scenesFactory.makeSendTokenViewController(activeWallet: wallet, destinationAddress: nil)
            self.present(vc, animated: true, completion: nil)
        case .receive:
            let vc = scenesFactory.makeReceiveTokenViewController(pubkey: viewModel.wallet.value?.pubkey)
            self.show(vc, sender: nil)
        case .swap:
            guard let wallet = viewModel.wallet.value else {return}
            let vc = scenesFactory.makeSwapTokenViewController(fromWallet: wallet)
            self.show(vc, sender: nil)
        case .transactionInfo(let transaction):
            let vc = TransactionInfoVC(transaction: transaction)
            present(vc, animated: true, completion: nil)
        }
    }
}

extension WalletDetailViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
