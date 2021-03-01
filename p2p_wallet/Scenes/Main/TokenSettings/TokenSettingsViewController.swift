//
//  TokenSettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation
import UIKit
import Action

protocol TokenSettingsScenesFactory {
    func makeProcessTransactionVC() -> ProcessTransactionVC
}

class TokenSettingsViewController: WLIndicatorModalVC {
    
    // MARK: - Properties
    let viewModel: TokenSettingsViewModel
    let scenesFactory: TokenSettingsScenesFactory
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(backgroundColor: .textWhite)
        navigationBar.backButton
            .onTap(self, action: #selector(back))
        navigationBar.titleLabel.text = L10n.walletSettings
        return navigationBar
    }()
    var transactionVC: ProcessTransactionVC!
    
    // MARK: - Initializer
    init(viewModel: TokenSettingsViewModel, scenesFactory: TokenSettingsScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        containerView.backgroundColor = .f6f6f8
        
        containerView.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let rootView = TokenSettingsRootView(viewModel: viewModel)
        containerView.addSubview(rootView)
        rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        rootView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 10)
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    func navigate(to scene: TokenSettingsNavigatableScene) {
        switch scene {
        case .closeConfirmation:
            guard let symbol = viewModel.wallet?.symbol else {return}
            let vc = TokenSettingsCloseAccountConfirmationVC(symbol: symbol)
            vc.completion = {
                vc.dismiss(animated: true) { [unowned self] in
                    self.viewModel.closeWallet()
                }
            }
            self.present(vc, animated: true, completion: nil)
        case .sendTransaction:
            self.transactionVC =
                self.scenesFactory.makeProcessTransactionVC()
            self.present(self.transactionVC, animated: true, completion: nil)
        case .processTransaction(signature: let signature):
            self.showProcessingTransaction(signature: signature)
        case .transactionError(let error):
            self.transactionVC.dismiss(animated: true) {
                self.showError(error)
            }
        }
    }
    
    // MARK: - Helpers
    private func showProcessingTransaction(signature: String) {
        transactionVC.signature = signature
        transactionVC.viewInExplorerButton.rx.action = CocoaAction {
            self.transactionVC.dismiss(animated: true) {
                let pc = self.presentingViewController
                self.back()
                pc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
            }
            
            return .just(())
        }
        transactionVC.goBackToWalletButton.rx.action = CocoaAction {
            self.transactionVC.dismiss(animated: true) {
                self.back()
            }
            return .just(())
        }
    }
}
