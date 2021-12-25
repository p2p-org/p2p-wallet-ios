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

extension WalletDetail {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: WalletDetailViewModelType
        
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
        init(pubkey: String, symbol: String) {
            super.init()
            viewModel.set(pubkey: pubkey, symbol: symbol)
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
            case .buy:
                let vc = BuyRoot.ViewController()
                present(vc, animated: true, completion: nil)
            case .settings(let pubkey):
                let vc = TokenSettingsViewController(pubkey: pubkey)
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            case .send(let wallet):
                let vc = SendToken.ViewController(walletPubkey: wallet.pubkey, destinationAddress: nil)
                show(vc, sender: nil)
            case .receive(let pubkey):
                if let solanaPubkey = try? SolanaSDK.PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let tokenWallet = viewModel.walletsRepository.getWallets().first(where: {$0.pubkey == pubkey})
                    
                    let isDevnet = Defaults.apiEndPoint.network == .devnet
                    let renBTCMint: SolanaSDK.PublicKey = isDevnet ? .renBTCMintDevnet : .renBTCMint
                    
                    let isRenBTCWalletCreated = viewModel.walletsRepository.getWallets().contains(where: {
                        $0.token.address == renBTCMint.base58EncodedString
                    })
                    let vc = ReceiveToken.ViewController(solanaPubkey: solanaPubkey, solanaTokenWallet: tokenWallet, isRenBTCWalletCreated: isRenBTCWalletCreated)
                    show(vc, sender: true)
                }
            case .swap(let wallet):
                let vc = OrcaSwapV2.ViewController(initialWallet: wallet)
                show(vc, sender: nil)
            case .transactionInfo(let transaction):
                let vc = TransactionInfoViewController(transaction: transaction)
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
