//
//  WalletDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import UIKit

extension WalletDetail {
    class ViewController: WLIndicatorModalVC {
        
        // MARK: - Properties
        let viewModel: ViewModel
        let scenesFactory: WalletDetailScenesFactory
        
        // MARK: - Initializer
        init(
            viewModel: ViewModel,
            scenesFactory: WalletDetailScenesFactory
        ) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let rootView = RootView(viewModel: viewModel)
            containerView.addSubview(rootView)
            rootView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .settings(let pubkey):
                let vc = scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            case .send(let wallet):
                let vc = scenesFactory.makeSendTokenViewController(walletPubkey: wallet.pubkey, destinationAddress: nil)
                self.present(vc, animated: true, completion: nil)
            case .receive(let pubkey):
                if let vc = scenesFactory.makeReceiveTokenViewController(tokenWalletPubkey: pubkey)
                {
                    self.show(vc, sender: nil)
                }
            case .swap(let wallet):
                let vc = scenesFactory.makeSwapTokenViewController(fromWallet: wallet)
                self.show(vc, sender: nil)
            case .transactionInfo(let transaction):
                let vc = scenesFactory.makeTransactionInfoViewController(transaction: transaction)
                present(vc, animated: true, completion: nil)
            default:
                break
            }
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
