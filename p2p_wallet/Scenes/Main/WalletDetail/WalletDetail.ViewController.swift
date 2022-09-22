//
//  WalletDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import BEPureLayout
import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit

extension WalletDetail {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: WalletDetailViewModelType

        // MARK: - Handler

        var processingTransactionDoneHandler: (() -> Void)?
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private lazy var balanceView = BalanceView(viewModel: viewModel)
        private let actionsView = ColorfulHorizontalView()

        // MARK: - Subscene

        private lazy var historyVC = History.Scene(account: viewModel.pubkey, symbol: viewModel.symbol)
        private var coordinator: SendToken.Coordinator?

        // MARK: - Initializer

        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
            hidesBottomBarWhenPushed = true
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()

            #if DEBUG
                let rightButton = UIBarButtonItem(
                    title: L10n.settings,
                    style: .plain,
                    target: self,
                    action: #selector(showWalletSettings)
                )
                rightButton.setTitleTextAttributes([.foregroundColor: UIColor.red], for: .normal)
                navigationItem.rightBarButtonItem = rightButton
            #endif

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
            stackView.autoPinEdge(toSuperviewSafeArea: .top)

            add(child: historyVC, to: containerView)
        }

        override func bind() {
            super.bind()
            viewModel.walletPublisher
                .map { $0?.token.name }
                .sink(receiveValue: { [weak self] in
                    self?.navigationItem.title = $0
                })
                .store(in: &subscriptions)

            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)

            viewModel.walletActionsPublisher
                .sink { [weak self] in
                    guard let self = self else { return }

                    self.actionsView.setArrangedSubviews($0.map(self.createWalletActionView))
                }
                .store(in: &subscriptions)
        }

        // MARK: - Navigation

        private var buyCoordinator: BuyCoordinator?
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case let .buy(crypto):
                let vc: UIViewController
                if available(.buyScenarioEnabled) {
                    // TODO: remove after moving to coordinator
                    buyCoordinator = BuyCoordinator(
                        context: .fromToken,
                        defaultToken: crypto,
                        presentingViewController: self,
                        shouldPush: false
                    )
                    buyCoordinator?.start().sink { _ in }.store(in: &subscriptions)
                } else {
                    vc = BuyPreparing.Scene(
                        viewModel: BuyPreparing.SceneModel(
                            crypto: crypto,
                            exchangeService: Resolver.resolve()
                        )
                    )
                    let navigation = UINavigationController(rootViewController: vc)
                    present(navigation, animated: true)
                }
            case let .settings(pubkey):
                break
//                let vm = TokenSettingsViewModel(pubkey: pubkey)
//                let vc = TokenSettingsViewController(viewModel: vm)
//                vc.delegate = self
//                present(vc, animated: true)
            case let .send(wallet):
                let vm = SendToken.ViewModel(
                    walletPubkey: wallet.pubkey,
                    destinationAddress: nil,
                    relayMethod: .default
                )
                if coordinator == nil, let navigationController = navigationController {
                    coordinator = SendToken.Coordinator(
                        viewModel: vm,
                        navigationController: navigationController
                    )
                    coordinator?.doneHandler = processingTransactionDoneHandler
                }
                coordinator?.start(hidesBottomBarWhenPushed: true)
            case let .receive(pubkey):
                if let solanaPubkey = try? PublicKey(string: viewModel.walletsRepository.nativeWallet?.pubkey) {
                    let tokenWallet = viewModel.walletsRepository.getWallets().first(where: { $0.pubkey == pubkey })

                    let vm = ReceiveToken.SceneModel(
                        solanaPubkey: solanaPubkey,
                        solanaTokenWallet: tokenWallet,
                        isOpeningFromToken: true
                    )
                    let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: true)
                    let navigation = UINavigationController(rootViewController: vc)
                    present(navigation, animated: true)
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
