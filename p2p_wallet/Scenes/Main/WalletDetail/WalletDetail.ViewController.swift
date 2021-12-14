//
//  WalletDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import BEPureLayout
import RxSwift
import UIKit

protocol WalletDetailScenesFactory {
    func makeBuyTokenViewController(token: BuyToken.CryptoCurrency) throws -> UIViewController
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.Scene?
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> UIViewController
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
    func makeTransactionInfoViewController(transaction: SolanaSDK.ParsedTransaction) -> TransactionInfoViewController
}

extension WalletDetail {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: WalletDetailViewModelType
        private let scenesFactory: WalletDetailScenesFactory
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))
            let editButton = UIImageView(width: 24, height: 24, image: .navigationBarEdit)
                .onTap(self, action: #selector(showWalletSettings))
            navigationBar.rightItems.addArrangedSubview(editButton)
            return navigationBar
        }()
        
        // MARK: - Subscene
        private lazy var infoVC: InfoViewController = {
            let vc = InfoViewController(viewModel: viewModel)
            return vc
        }()
        
        private lazy var historyVC: HistoryViewController = {
            let vc = HistoryViewController(viewModel: viewModel)
            return vc
        }()
        
        // MARK: - Initializer
        init(
            viewModel: WalletDetailViewModelType,
            scenesFactory: WalletDetailScenesFactory
        ) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            let containerView = UIView(forAutoLayout: ())
            view.addSubview(containerView)
            containerView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            
            let pagesVC = WLSegmentedPagesVC(items: [
                .init(label: L10n.info, viewController: infoVC),
                .init(label: L10n.history, viewController: historyVC)
            ])
            add(child: pagesVC, to: containerView)
        }
        
        override func bind() {
            super.bind()
            viewModel.walletDriver.map { $0?.name }
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
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
                show(vc, sender: nil)
            case .receive(let pubkey):
                if let vc = scenesFactory.makeReceiveTokenViewController(tokenWalletPubkey: pubkey) {
                    show(vc, sender: true)
                }
            case .swap(let wallet):
                let vc = scenesFactory.makeSwapTokenViewController(provider: .orca, fromWallet: wallet)
                show(vc, sender: nil)
            case .transactionInfo(let transaction):
                let vc = scenesFactory.makeTransactionInfoViewController(transaction: transaction)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            default:
                break
            }
        }
        
        // MARK: - Actions
        @objc func showWalletSettings() {
            viewModel.showWalletSettings()
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
