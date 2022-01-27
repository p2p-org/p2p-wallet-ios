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
        private let viewModel: WalletDetailViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subviews
        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))

            return navigationBar
        }()
        private lazy var balanceView = BalanceView(viewModel: viewModel)
        private let actionsView = ColorfulHorizontalView()
        
        // MARK: - Subscene
        private lazy var historyVC = HistoryViewController(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            let containerView = UIView(forAutoLayout: ())

            actionsView.autoSetDimension(.height, toSize: 80)

            let stackView = UIStackView(
                axis: .vertical,
                spacing: 18,
                alignment: .fill
            ) {
                balanceView.padding(.init(x: 18, y: 16))
                actionsView.padding(.init(x: 18, y: 0))
                containerView.padding(.init(top: 16, left: 8, bottom: 0, right: 8))
            }

            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            stackView.autoPinEdge(.top, to: .bottom, of: navigationBar)

            add(child: historyVC, to: containerView)
        }
        
        override func bind() {
            super.bind()
            viewModel.walletDriver.map { $0?.token.name }
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            viewModel.walletActionsDriver
                .drive(
                    onNext: { [weak self] in
                        guard let self = self else  { return }

                        self.actionsView.setArrangedSubviews($0.map(self.createWalletActionView))
                    }
                )
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .buy:
                let vm = BuyRoot.ViewModel()
                let vc = BuyRoot.ViewController(viewModel: vm)
                present(vc, animated: true, completion: nil)
            case .settings(let pubkey):
                let vm = TokenSettingsViewModel(pubkey: pubkey)
                let vc = TokenSettingsViewController(viewModel: vm)
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            case .send(let wallet):
                let vm = SendToken.ViewModel(walletPubkey: wallet.pubkey)
                let vc = SendToken.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .receive(let pubkey):
                if let solanaPubkey = try? SolanaSDK.PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let tokenWallet = viewModel.walletsRepository.getWallets().first(where: {$0.pubkey == pubkey})
                    
                    let isDevnet = Defaults.apiEndPoint.network == .devnet
                    let renBTCMint: SolanaSDK.PublicKey = isDevnet ? .renBTCMintDevnet : .renBTCMint
                    
                    let isRenBTCWalletCreated = viewModel.walletsRepository.getWallets().contains(where: {
                        $0.token.address == renBTCMint.base58EncodedString
                    })
                    let vm = ReceiveToken.SceneModel(
                        solanaPubkey: solanaPubkey,
                        solanaTokenWallet: tokenWallet,
                        isRenBTCWalletCreated: isRenBTCWalletCreated,
                        isOpeningFromToken: true
                    )
                    let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: true)
                    present(vc, animated: true)
                }
            case .swap(let wallet):
                let vm = OrcaSwapV2.ViewModel(initialWallet: wallet)
                let vc = OrcaSwapV2.ViewController(viewModel: vm)
                show(vc, sender: nil)
            case .transactionInfo(let transaction):
                let vm = TransactionInfoViewModel(transaction: transaction)
                let vc = TransactionInfoViewController(viewModel: vm)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            default:
                break
            }
        }

        private func createWalletActionView(actionType: WalletActionType) -> UIView {
            return WalletActionButton(actionType: actionType) { [weak self] in
                self?.viewModel.start(action: actionType)
            }
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken() {
        dismiss(animated: true, completion: nil)
    }
}
