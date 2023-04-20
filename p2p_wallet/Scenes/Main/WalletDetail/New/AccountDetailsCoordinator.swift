//
//  AccountDetailsCoordiantor.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Combine
import KeyAppBusiness
import KeyAppUI
import Sell
import SolanaSwift
import SwiftUI
import UIKit
import Wormhole

enum AccountDetailsCoordinatorArgs {
    case solanaAccount(SolanaAccountsService.Account)
}

enum AccountDetailsCoordinatorResult {
    case cancel
    case done
}

class AccountDetailsCoordinator: SmartCoordinator<AccountDetailsCoordinatorResult> {
    let args: AccountDetailsCoordinatorArgs

    init(args: AccountDetailsCoordinatorArgs, presentingViewController: UINavigationController) {
        self.args = args
        super.init(presentation: SmartCoordinatorPushPresentation(presentingViewController))
    }

    override func build() -> UIViewController {
        let detailAccountVM: AccountDetailsViewModel
        let historyListVM: AccountDetailsHistoryViewModel

        switch args {
        case let .solanaAccount(account):
            detailAccountVM = .init(solanaAccount: account)
            historyListVM = .init(mint: account.data.token.address, account: account)
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

        let view = AccountDetailsView(
            detailAccount: detailAccountVM,
            historyList: historyListVM
        )

        let vc = UIHostingController(rootView: view)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.onClose = { [weak self] in self?.result.send(.cancel) }
        vc.title = detailAccountVM.rendableAccountDetails.title

        return vc
    }

    private func openDetailTransaction(action: NewHistoryAction) {
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

        case let .openUserAction(userAction):
            let coordinator = TransactionDetailCoordinator(
                viewModel: .init(userAction: userAction),
                presentingViewController: presentation.presentingViewController
            )

            coordinate(to: coordinator)
                .sink { _ in }
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
            openSell(trx)

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

        case let .openSwap(wallet, destination):
            openSwap(destination: destination)

        case .openSentViaLinkHistoryView:
            break
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
        guard case let .solanaAccount(account) = args,
              let navigationController = presentation.presentingViewController as? UINavigationController
        else {
            return
        }

        let supportedBridgeTokens = Wormhole.SupportedToken.bridges
            .map(\.solAddress)
            .compactMap { $0 } +
            Wormhole.SupportedToken.bridges
            .map(\.receiveFromAddress)
            .compactMap { $0 }

        if available(.ethAddressEnabled) &&
            (account.data.isNativeSOL || supportedBridgeTokens.contains(account.data.token.address))
        {
            var icon: SupportedTokenItemIcon = .image(UIImage.imageOutlineIcon)
            if let logoURL = URL(string: account.data.token.logoURI ?? "") {
                icon = .url(logoURL)
            }
            openReceive(item:
                .init(
                    icon: icon,
                    name: account.data.name,
                    symbol: account.data.token.symbol,
                    availableNetwork: [.solana, .ethereum]
                ))
        } else {
            let coordinator = ReceiveCoordinator(
                network: .solana(
                    tokenSymbol: account.data.token.symbol,
                    tokenImage: .init(token: account.data.token)
                ),
                presentation: SmartCoordinatorPushPresentation(navigationController)
            )
            coordinator.start().sink { _ in }.store(in: &subscriptions)
        }
    }

    private func openReceive(item: SupportedTokenItem) {
        // Coordinate to receive
        func _openReceive(network: ReceiveNetwork) {
            coordinate(to: ReceiveCoordinator(network: network, presentation: presentation))
                .sink {}
                .store(in: &subscriptions)
        }

        let image = ReceiveNetwork.Image(icon: item.icon)

        if item.availableNetwork.count == 1, let network = item.availableNetwork.first {
            // Token supports only one network.
            switch network {
            case .solana:
                _openReceive(network: .solana(tokenSymbol: item.symbol, tokenImage: image))
            case .ethereum:
                _openReceive(network: .ethereum(tokenSymbol: item.symbol, tokenImage: image))
            }
        } else {
            // Token supports many networks.
            let coordinator = SupportedTokenNetworksCoordinator(
                supportedToken: item,
                viewController: presentation.presentingViewController
            )
            coordinate(to: coordinator)
                .sink { selectedNetwork in
                    guard let selectedNetwork else { return }
                    switch selectedNetwork {
                    case .solana:
                        _openReceive(network: .solana(tokenSymbol: item.symbol, tokenImage: image))
                    case .ethereum:
                        _openReceive(network: .ethereum(tokenSymbol: item.symbol, tokenImage: image))
                    }
                }
                .store(in: &subscriptions)
        }
    }

    func openSwap(destination: Wallet? = nil) {
        guard case let .solanaAccount(account) = args,
              let rootViewController = presentation.presentingViewController as? UINavigationController
        else { return }
        coordinate(
            to: JupiterSwapCoordinator(
                navigationController: rootViewController,
                params: .init(
                    dismissAfterCompletion: true,
                    openKeyboardOnStart: true,
                    source: .tapToken,
                    preChosenWallet: account.data,
                    destinationWallet: destination,
                    hideTabBar: true
                )
            )
        )
        .sink { [weak rootViewController] _ in
            rootViewController?.popToRootViewController(animated: true)
        }
        .store(in: &subscriptions)
    }

    func openSend() {
        guard
            case let .solanaAccount(account) = args,
            let rootViewController = presentation.presentingViewController as? UINavigationController,
            let currentVC = rootViewController.viewControllers.last
        else { return }

        let coordinator = SendCoordinator(
            rootViewController: rootViewController,
            preChosenWallet: account.data,
            hideTabBar: true,
            allowSwitchingMainAmountType: true
        )

        coordinate(to: coordinator)
            .sink { [weak self] result in
                guard let self = self else { return }

                switch result {
                case let .wormhole(trx):
                    rootViewController.popToViewController(currentVC, animated: true)

                    self
                        .coordinate(to: TransactionDetailCoordinator(
                            viewModel: .init(userAction: trx),
                            presentingViewController: rootViewController
                        ))
                        .sink(receiveValue: { _ in })
                        .store(in: &self.subscriptions)

                case let .sent(model):
                    rootViewController.popToViewController(currentVC, animated: true)

                    self
                        .coordinate(to: SendTransactionStatusCoordinator(
                            parentController: rootViewController,
                            transaction: model
                        ))
                        .sink(receiveValue: {})
                        .store(in: &self.subscriptions)
                case .sentViaLink:
                    rootViewController.popToViewController(currentVC, animated: true)

//                    self.coordinate(to: SendTransactionStatusCoordinator(parentController: rootViewController, transaction: model))
//                        .sink(receiveValue: {})
//                        .store(in: &self.subscriptions)
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func openBuy() {
        guard case let .solanaAccount(account) = args else { return }

        let token: Token
        switch account.data.token.symbol {
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
            presentingViewController: presentation.presentingViewController,
            shouldPush: false
        )

        coordinate(to: coordinator)
            .sink { _ in }
            .store(in: &subscriptions)
    }
}

extension ReceiveNetwork.Image {
    init?(token: Token) {
        if let image = token.image {
            self = .image(image)
        } else if let urlStr = token.logoURI, let url = URL(string: urlStr) {
            self = .url(url)
        } else {
            return nil
        }
    }
}
