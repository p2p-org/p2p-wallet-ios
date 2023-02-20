//
//  NewHistoryCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import KeyAppUI
import Resolver
import Sell
import Send
import SwiftUI

class NewHistoryCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let vm = NewHistoryViewModel()

        vm.actionSubject
            .sink { [weak self] action in
                self?.openDetailTransaction(action: action)
            }
            .store(in: &subscriptions)

        let view = NewHistoryView(viewModel: vm, header: SwiftUI.EmptyView())
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        vc.navigationIsHidden = false
        vc.title = L10n.history
        vc.view.backgroundColor = Asset.Colors.smoke.color

        vc.viewDidAppear.sink {
            vc.navigationItem.largeTitleDisplayMode = .always
        }.store(in: &subscriptions)

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
}
