//
//  WalletDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import BEPureLayout
import Foundation
import RxSwift
import SolanaSwift
import UIKit

extension WalletDetail {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies

        private let viewModel: WalletDetailViewModelType

        // MARK: - Handler

        var processingTransactionDoneHandler: (() -> Void)?

        // MARK: - Subviews

        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))
            #if DEBUG
                navigationBar.rightItems.addArrangedSubview(
                    UIButton(label: "Settings", textColor: .red)
                        .onTap { [weak self] in
                            self?.viewModel.showWalletSettings()
                        }
                )
            #endif
            return navigationBar
        }()

        private lazy var balanceView = BalanceView(viewModel: viewModel)
        private let actionsView = ColorfulHorizontalView()

        // MARK: - Subscene

        private lazy var historyVC = History
            .Scene(account: viewModel.pubkey, symbol: viewModel.symbol) // HistoryViewController(viewModel: viewModel)

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
                        guard let self = self else { return }

                        self.actionsView.setArrangedSubviews($0.map(self.createWalletActionView))
                    }
                )
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case let .buy(crypto):
                let vm = BuyRoot.ViewModel()
                let vc = BuyRoot.ViewController(crypto: crypto, viewModel: vm)
                present(vc, animated: true, completion: nil)
            case let .settings(pubkey):
                let vm = TokenSettingsViewModel(pubkey: pubkey)
                let vc = TokenSettingsViewController(viewModel: vm)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            case let .send(wallet):
                let vm = SendToken.ViewModel(
                    walletPubkey: wallet.pubkey,
                    destinationAddress: nil,
                    relayMethod: .default
                )
                let vc = SendToken.ViewController(viewModel: vm)
                vc.doneHandler = processingTransactionDoneHandler
                show(vc, sender: nil)
            case let .receive(pubkey):
                if let solanaPubkey = try? PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let tokenWallet = viewModel.walletsRepository.getWallets().first(where: { $0.pubkey == pubkey })

                    let vm = ReceiveToken.SceneModel(
                        solanaPubkey: solanaPubkey,
                        solanaTokenWallet: tokenWallet,
                        isOpeningFromToken: true
                    )
                    let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: true)
                    present(vc, animated: true)
                }
            case let .swap(wallet):
                let vm = OrcaSwapV2.ViewModel(initialWallet: wallet)
                let vc = OrcaSwapV2.ViewController(viewModel: vm)
                vc.doneHandler = processingTransactionDoneHandler
                show(vc, sender: nil)
            case let .transactionInfo(transaction):
                let vm = TransactionDetail.ViewModel(parsedTransaction: transaction)
                let vc = TransactionDetail.ViewController(viewModel: vm)
                show(vc, sender: nil)
            default:
                break
            }
        }

        private func createWalletActionView(actionType: WalletActionType) -> UIView {
            WalletActionButton(actionType: actionType) { [weak self] in
                self?.viewModel.start(action: actionType)
            }
        }

        // MARK: - Actions

        @objc func showWalletSettings() {
            viewModel.showWalletSettings()
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
