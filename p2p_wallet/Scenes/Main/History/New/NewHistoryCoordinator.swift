//
//  NewHistoryCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Combine
import Foundation
import KeyAppUI
import Resolver
import Sell
import Send
import SolanaSwift
import SwiftUI

class NewHistoryCoordinator: SmartCoordinator<Void> {
    var viewModel: HistoryViewModel!

    override func build() -> UIViewController {
        viewModel = HistoryViewModel()

        viewModel.actionSubject
            .sink { [weak self] action in
                self?.openAction(action: action)
            }
            .store(in: &subscriptions)

        let view = NewHistoryView(viewModel: viewModel, header: SwiftUI.EmptyView())
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        vc.navigationIsHidden = false
        vc.title = L10n.history
        vc.view.backgroundColor = Asset.Colors.smoke.color

        vc.viewDidAppear.sink {
            vc.navigationItem.largeTitleDisplayMode = .never
        }.store(in: &subscriptions)

        return vc
    }

    private func openAction(action: NewHistoryAction) {
        switch action {
        case let .openParsedTransaction(trx):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(parsedTransaction: trx),
                presentingViewController: presentation.presentingViewController
            )

            coordinate(to: coordinator)
                .sink { result in
                    print(result)
                }
                .store(in: &subscriptions)

        case let .openHistoryTransaction(trx):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(historyTransaction: trx),
                presentingViewController: presentation.presentingViewController
            )

            coordinate(to: coordinator)
                .sink { _ in }
                .store(in: &subscriptions)

        case let .openSellTransaction(trx):
            openSellTransactionDetail(trx)

        case let .openPendingTransaction(trx):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(pendingTransaction: trx),
                presentingViewController: presentation.presentingViewController
            )

            coordinate(to: coordinator)
                .sink { result in
                    print(result)
                }
                .store(in: &subscriptions)

        case .openBuy:
            openBuy()

        case .openReceive:
            openReceive()

        case let .openSwap(wallet, destinationWallet):
            openSwap(wallet: wallet, destination: destinationWallet)

        case let .openSentViaLinkHistoryView:
            openSentViaLinkHistoryView()

        case let .openUserAction(userAction):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(userAction: userAction),
                presentingViewController: presentation.presentingViewController
            )

            coordinate(to: coordinator)
                .sink { result in
                    print(result)
                }
                .store(in: &subscriptions)
        }
    }

    private func openSellTransactionDetail(_ transaction: SellDataServiceTransaction) {
        let strategy: SellTransactionDetailsViewModel.Strategy
        switch transaction.status {
        case .completed:
            strategy = .fundsWereSent
        case .waitingForDeposit:
            strategy = .youNeedToSend(receiverAddress: transaction.depositWallet)
        case .pending:
            strategy = .processing
        case .failed:
            strategy = .youVeNotSent
        }

        coordinate(to:
            SellTransactionDetailsCoorditor(
                viewController: presentation.presentingViewController,
                strategy: .notSuccess(strategy),
                transaction: transaction,
                fiat: .usd,
                date: transaction.createdAt ?? Date()
            ))
            .sink { [weak self] result in
                guard let self else { return }
                switch result {
                case .send:
                    self.presentation.presentingViewController.presentedViewController?.dismiss(animated: true) {
                        self.openSend(transaction)
                    }
                case .tryAgain:
                    self.presentation.presentingViewController.presentedViewController?.dismiss(animated: true) {
                        self.openSell(transaction)
                    }
                default:
                    break
                }
            }
            .store(in: &subscriptions)
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

    private func openSend(_ transaction: SellDataServiceTransaction) {
        guard let viewController = presentation.presentingViewController as? UINavigationController else {
            print(SmartCoordinatorError.unsupportedPresentingViewController)
            return
        }

        let walletsRepository = Resolver.resolve(WalletsRepository.self)
        coordinate(to: SendCoordinator(
            rootViewController: viewController,
            preChosenWallet: walletsRepository.nativeWallet,
            preChosenRecipient: Recipient(
                address: transaction.depositWallet,
                category: .solanaAddress,
                attributes: [.funds]
            ),
            preChosenAmount: transaction.baseCurrencyAmount,
            allowSwitchingMainAmountType: false
        ))
        .sink { _ in }
        .store(in: &subscriptions)
    }

    private func openReceive() {
        let userWalletManager: UserWalletManager = Resolver.resolve()
        guard let account = userWalletManager.wallet?.account else { return }

        let vm = ReceiveToken.SceneModel(solanaPubkey: account.publicKey)
        let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: true)
        let navigation = UINavigationController(rootViewController: vc)
        presentation.presentingViewController.present(navigation, animated: true)
    }

    func openSwap(wallet: Wallet?, destination: Wallet? = nil) {
        guard let navigationController = presentation.presentingViewController as? UINavigationController else {
            return
        }
        let coordinator = SwapCoordinator(
            navigationController: navigationController,
            initialWallet: wallet,
            destinationWallet: destination,
            hidesBottomBarWhenPushed: true
        )

        coordinate(to: coordinator)
            .sink { _ in }
            .store(in: &subscriptions)
    }

    func openBuy() {
        let coordinator = BuyCoordinator(
            context: .fromToken,
            defaultToken: .nativeSolana,
            presentingViewController: presentation.presentingViewController,
            shouldPush: false
        )

        coordinate(to: coordinator)
            .sink { _ in }
            .store(in: &subscriptions)
    }

    private func openSentViaLinkHistoryView() {
        let coordinator = SentViaLinkHistoryCoordinator(
            presentation: SmartCoordinatorPushPresentation(presentation
                .presentingViewController as! UINavigationController)
        )

        coordinate(to: coordinator)
            .sink { _ in }
            .store(in: &subscriptions)
    }

    func openUserAction() {}
}
