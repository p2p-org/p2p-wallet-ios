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
import RxCombine
import RxSwift
import SolanaSwift
import KeyAppUI
import UIKit

extension WalletDetail {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: WalletDetailViewModelType

        // MARK: - Handler

        var processingTransactionDoneHandler: (() -> Void)?

        // MARK: - Subscene

        private lazy var historyVC = History.Scene(account: viewModel.pubkey, symbol: viewModel.symbol)
        private var coordinator: SendCoordinator?
        private var sendTransactionStatusCoordinator: SendTransactionStatusCoordinator?
        private var subscriptions = Set<AnyCancellable>()

        // MARK: - Initializer

        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
            hidesBottomBarWhenPushed = true
            navigationItem.largeTitleDisplayMode = .never
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

            let actionsPublisher = viewModel.walletActionsDriver
                .asPublisher()
                .assertNoFailure()
            let balancePublisher = viewModel.walletDriver
                .asPublisher()
                .assertNoFailure()
                .compactMap { $0?.amount?.tokenAmount(symbol: $0?.token.symbol ?? "") }
            let usdAmountPublisher = viewModel.walletDriver
                .asPublisher()
                .assertNoFailure()
                .compactMap { $0?.amountInCurrentFiat.fiatAmount() }
            let actionsView = ActionsPanelView(
                actionsPublisher: actionsPublisher.eraseToAnyPublisher(),
                balancePublisher: balancePublisher.eraseToAnyPublisher(),
                usdAmountPublisher: usdAmountPublisher.eraseToAnyPublisher()
            ) { [unowned self] actionType in
                viewModel.start(action: actionType)
            }.uiView()

            view.addSubview(actionsView)
            actionsView.autoPinEdge(toSuperviewSafeArea: .top)
            actionsView.autoPinEdge(toSuperviewEdge: .leading)
            actionsView.autoPinEdge(toSuperviewEdge: .trailing)
            actionsView.heightAnchor.constraint(equalToConstant: 228).isActive = true

            view.addSubview(containerView)
            containerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            containerView.autoPinEdge(.top, to: .bottom, of: actionsView)

            add(child: historyVC, to: containerView)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            view.layoutIfNeeded()
        }

        override func bind() {
            super.bind()

            viewModel.walletDriver
                .map { $0?.token.name }
                .drive(onNext: { [weak self] in
                    self?.navigationItem.title = $0
                })
                .disposed(by: disposeBag)
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private var buyCoordinator: BuyCoordinator?
        private var sellCoordinator: SellCoordinator?
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case let .buy(crypto):
                let vc: UIViewController
                if available(.buyScenarioEnabled) {
                    // TODO: remove after moving to coordinator
                    buyCoordinator = BuyCoordinator(
                        context: .fromToken,
                        defaultToken: crypto == .sol ? .nativeSolana : crypto == .usdc ? .usdc : .eth,
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
                let vm = TokenSettingsViewModel(pubkey: pubkey)
                let vc = TokenSettingsViewController(viewModel: vm)
                vc.delegate = self
                present(vc, animated: true)
            case let .send(wallet):
                coordinator = SendCoordinator(rootViewController: navigationController!, preChosenWallet: wallet, hideTabBar: true)
                coordinator?.start()
                    .sink { [weak self] result in
                        switch result {
                        case let .sent(model):
                            self?.navigationController?.popToViewController(ofClass: Self.self, animated: true)
                            self?.showSendTransactionStatus(model: model)
                        case .cancelled:
                            break
                        }
                    }
                    .store(in: &subscriptions)
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

        // MARK: - Actions

        @objc func showWalletSettings() {
            viewModel.showWalletSettings()
        }
        
        private func showSendTransactionStatus(model: SendTransaction) {
            sendTransactionStatusCoordinator = SendTransactionStatusCoordinator(parentController: navigationController!, transaction: model)
            
            sendTransactionStatusCoordinator?
                .start()
                .sink(receiveValue: { })
                .store(in: &subscriptions)
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
