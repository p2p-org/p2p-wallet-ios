//
//  DetailAccountCoordiantor.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Sell
import SolanaSwift
import SwiftUI
import UIKit

enum DetailAccountCoordinatorArgs {
    case wallet(Wallet)
}

enum DetailAccountCoordinatorResult {
    case cancel
    case done
}

class DetailAccountCoordinator: SmartCoordinator<DetailAccountCoordinatorResult> {
    let args: DetailAccountCoordinatorArgs

    init(args: DetailAccountCoordinatorArgs, presentingViewController: UINavigationController) {
        self.args = args
        super.init(presentation: SmartCoordinatorPushPresentation(presentingViewController))
    }

    override func build() -> UIViewController {
        let detailAccountVM: DetailAccountViewModel
        let historyListVM: HistoryViewModel

        switch self.args {
        case let .wallet(wallet):
            detailAccountVM = .init(wallet: wallet)
            historyListVM = .init(mint: wallet.mintAddress)
        }

        historyListVM.actionSubject
            .sink { [weak self] action in
                self?.openDetailTransaction(action: action)
            }
            .store(in: &subscriptions)

        detailAccountVM.actionSubject.sink { [weak self] action in
            guard let self else { return }

            switch action {
            case .openBuy:
                self.openBuy()
            case .openReceive:
                self.openReceive()
            case .openSend:
                self.openSend()
            case .openSwap:
                self.openSwap()
            }
        }
        .store(in: &subscriptions)

        let view = DetailAccountView(
            detailAccount: detailAccountVM,
            historyList: historyListVM
        )

        let vc = UIHostingController(rootView: view)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.onClose = { [weak self] in self?.result.send(.cancel) }
        vc.title = detailAccountVM.rendableAccountDetail.title

        return vc
    }

    private func openDetailTransaction(action: NewHistoryAction) {
        switch action {
        case let .openParsedTransaction(trx):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(parsedTransaction: trx),
                presentingViewController: self.presentation.presentingViewController
            )

            self.coordinate(to: coordinator)
                .sink { result in
                    print(result)
                }
                .store(in: &self.subscriptions)

        case let .openHistoryTransaction(trx):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(historyTransaction: trx),
                presentingViewController: self.presentation.presentingViewController
            )

            self.coordinate(to: coordinator)
                .sink { _ in }
                .store(in: &self.subscriptions)

        case let .openSellTransaction(trx):
            self.openSell(trx)

        case let .openPendingTransaction(trx):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(pendingTransaction: trx),
                presentingViewController: self.presentation.presentingViewController
            )

            self.coordinate(to: coordinator)
                .sink { result in
                    print(result)
                }
                .store(in: &self.subscriptions)

        case .openBuy:
            self.openBuy()

        case .openReceive:
            self.openReceive()
        }
    }

    private func openSell(_ transaction: SellDataServiceTransaction) {
        guard let navigationController = presentation.presentingViewController as? UINavigationController else {
            print(SmartCoordinatorError.unsupportedPresentingViewController)
            return
        }

        coordinate(to: SellCoordinator(
            initialAmountInToken: transaction.baseCurrencyAmount,
            navigationController: navigationController
        ))
        .sink { _ in }
        .store(in: &subscriptions)
    }

    func openReceive() {
        guard case let .wallet(wallet) = self.args else { return }

        if let solanaPubkey = try? PublicKey(string: wallet.pubkey ?? "") {
            let vm = ReceiveToken.SceneModel(
                solanaPubkey: solanaPubkey,
                solanaTokenWallet: wallet,
                isOpeningFromToken: true
            )
            let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: true)
            let navigation = UINavigationController(rootViewController: vc)
            presentation.presentingViewController.present(navigation, animated: true)
        }
    }

    func openSwap() {
        guard case let .wallet(wallet) = self.args,
              let rootViewController = presentation.presentingViewController as? UINavigationController
        else { return }
        if available(.jupiterSwapEnabled) {
            coordinate(
                to: JupiterSwapCoordinator(
                    navigationController: rootViewController,
                    params: JupiterSwapParameters(dismissAfterCompletion: true, openKeyboardOnStart: true, source: .tapToken)
                )
            )
                .sink { [weak rootViewController] _ in
                    rootViewController?.popToRootViewController(animated: true)
                }
                .store(in: &subscriptions)
        } else {
            let vm = OrcaSwapV2.ViewModel(initialWallet: wallet)
            let vc = OrcaSwapV2.ViewController(viewModel: vm)
            
            vc.doneHandler = { [weak self, weak rootViewController] in
                rootViewController?.popToRootViewController(animated: true)
                self?.result.send(.done)
            }
            rootViewController.pushViewController(vc, animated: true)
        }
    }

    func openSend() {
        guard
            case let .wallet(wallet) = self.args,
            let rootViewController = presentation.presentingViewController as? UINavigationController,
            let currentVC = rootViewController.viewControllers.last
        else { return }

        let coordinator = SendCoordinator(
            rootViewController: rootViewController,
            preChosenWallet: wallet,
            hideTabBar: true,
            allowSwitchingMainAmountType: true
        )

        coordinate(to: coordinator)
            .sink { [weak self] result in
                guard let self = self else { return }

                switch result {
                case let .sent(model):
                    rootViewController.popToViewController(currentVC, animated: true)

                    self.coordinate(to: SendTransactionStatusCoordinator(parentController: rootViewController, transaction: model))
                        .sink(receiveValue: {})
                        .store(in: &self.subscriptions)
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func openBuy() {
        guard case let .wallet(wallet) = self.args else { return }

        let token: Token
        switch wallet.token.symbol {
        case "SOL":
            token = .nativeSolana
        case "USDC":
            token = .usdc
        default:
            token = .eth
        }

        let coordinator = BuyCoordinator(
            context: .fromToken,
            defaultToken: token,
            presentingViewController: self.presentation.presentingViewController,
            shouldPush: false
        )

        coordinate(to: coordinator)
            .sink { _ in }
            .store(in: &subscriptions)
    }
}
