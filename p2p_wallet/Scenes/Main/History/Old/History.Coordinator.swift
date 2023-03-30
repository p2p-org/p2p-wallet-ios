// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Send
import Sell

class HistoryCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let scene = History.Scene()

        scene.viewModel.onTapPublisher
            .sink { [weak self] item in
                switch item {
                case .parsedTransaction:
                    // TODO: Move navigation in VC to Coordinator
                    break
                case let .sellTransaction(transaction):
                    self?.showSellTransaction(transaction)
                }
            }
            .store(in: &subscriptions)

        return scene
    }

    private func showSellTransaction(_ transaction: SellDataServiceTransaction) {
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
            )
        )
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
}
