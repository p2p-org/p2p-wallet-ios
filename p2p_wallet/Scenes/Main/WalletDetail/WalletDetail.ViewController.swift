//
//  WalletDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import UIKit

extension WalletDetail {
    class ViewController: WLIndicatorModalVC, CustomPresentableViewController {
        var transitionManager: UIViewControllerTransitioningDelegate?
        
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
            case .buy(let tokens):
                do {
                    let vc = try scenesFactory.makeBuyTokenViewController(token: tokens)
                    present(vc, animated: true, completion: nil)
                } catch {
                    showAlert(title: L10n.error, message: error.readableDescription)
                }
            case .settings(let pubkey):
                let vc = scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            case .send(let wallet):
                let vc = scenesFactory.makeSendTokenViewController(walletPubkey: wallet.pubkey, destinationAddress: nil)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case .receive(let pubkey):
                if let vc = scenesFactory.makeReceiveTokenViewController(tokenWalletPubkey: pubkey)
                {
                    present(vc, interactiveDismissalType: .standard, completion: nil)
                }
            case .swap(let wallet):
                let vc = scenesFactory.makeNewSwapTokenViewController(fromWallet: wallet)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case .transactionInfo(let transaction):
                let vc = scenesFactory.makeTransactionInfoViewController(transaction: transaction)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            default:
                break
            }
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            .infinity
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
