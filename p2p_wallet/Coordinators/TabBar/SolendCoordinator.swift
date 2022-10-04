//
//  SolendCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 02.10.2022.
//

import Combine
import Foundation
import UIKit

final class SolendCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let transition = PanelTransition()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let investViewModel = InvestSolendViewModel()
        let investVC = InvestSolendView(viewModel: investViewModel)
            .asViewController() as! UIHostingControllerWithoutNavigation<InvestSolendView>
        navigationController.setViewControllers([investVC], animated: false)

        investVC.viewWillAppear
            .sink(receiveValue: { [unowned investVC] in
                investVC.navigationIsHidden = true
            })
            .store(in: &subscriptions)

        investVC.viewWillDisappear
            .sink(receiveValue: { [unowned investVC] in
                investVC.navigationIsHidden = false
            })
            .store(in: &subscriptions)

        investViewModel.deposit
            .sink(receiveValue: { [unowned self] in
                let viewModel = try! DepositSolendViewModel(initialAsset: $0)
                viewModel.finish.sink { [unowned self] in
                    navigationController.popViewController(animated: true)
                }.store(in: &subscriptions)

                let view = DepositSolendView(viewModel: viewModel)
                let depositVC = view.asViewController(withoutUIKitNavBar: false)
                navigationController.pushViewController(
                    depositVC,
                    animated: true
                )

                viewModel.transactionDetails
                    .flatMap { [unowned self] strategy -> AnyPublisher<Void, Never> in
                        let coordinator = SolendTransactionDetailsCoordinator(
                            controller: depositVC,
                            strategy: strategy,
                            model: viewModel.detailItem.eraseToAnyPublisher()
                        )
                        return self.coordinate(to: coordinator)
                    }
                    .sink(receiveValue: { _ in })
                    .store(in: &subscriptions)

                viewModel.tokenSelect
                    .flatMap { [unowned self] tokens -> AnyPublisher<SolendTokenActionCoordinator.Result, Never> in
                        var coordinator: SolendTokenActionCoordinator!
                        if let tokens = tokens as? [TokenToDepositView.Model] {
                            coordinator = SolendTokenActionCoordinator(
                                controller: depositVC,
                                strategy: .tokenToDeposit(model: tokens)
                            )
                        } else if let tokens = tokens as? [TokenToWithdrawView.Model] {
                            coordinator = SolendTokenActionCoordinator(
                                controller: depositVC,
                                strategy: .tokenToWithdraw(model: tokens)
                            )
                        }
                        return self.coordinate(to: coordinator)
                    }
                    .sink(receiveValue: { [weak viewModel] result in
                        switch result {
                        case let .symbol(symbol):
                            viewModel?.symbolSelected.send(symbol)
                        default:
                            break
                        }
                    })
                    .store(in: &subscriptions)

                viewModel.aboutSolend
                    .sink(receiveValue: { [unowned self] in
                        showAboutSolend(depositVC: depositVC)
                    })
                    .store(in: &subscriptions)

            })
            .store(in: &subscriptions)

        investViewModel.deposits.sink { [unowned self] _ in
            let coordinator = SolendDepositsCoordinator(controller: navigationController)
            self.coordinate(to: coordinator)
                .sink {}
                .store(in: &subscriptions)
        }.store(in: &subscriptions)

        investViewModel.topUpForContinue
            .sink(receiveValue: { [unowned self] in
                let coordinator = SolendTopUpForContinueCoordinator(
                    navigationController: navigationController,
                    model: $0
                )
                coordinate(to: coordinator)
                    .sink(receiveValue: { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .showTrade:
                            Task {
                                let done = await self.showTrade()
                                if done {
                                    self.navigationController.dismiss(animated: true)
                                }
                            }
                        case let .showBuy(symbol): self.showBuy(symbol: symbol)
                        default: break
                        }
                    })
                    .store(in: &subscriptions)
            })
            .store(in: &subscriptions)

        return Empty(completeImmediately: false)
            .eraseToAnyPublisher()
    }

    private func showBuy(symbol: String) {
        // Preparing params for buy view model
        var defaultToken: Buy.CryptoCurrency?
        var targetSymbol: String?
        switch symbol {
        case "USDC": defaultToken = Buy.CryptoCurrency.usdc
        case "SOL": defaultToken = Buy.CryptoCurrency.sol
        default: targetSymbol = symbol
        }

        let coordinator = BuyCoordinator(
            navigationController: navigationController,
            context: .fromInvest,
            defaultToken: defaultToken,
            targetTokenSymbol: targetSymbol
        )

        coordinate(to: coordinator)
            .sink {}
            .store(in: &subscriptions)
    }

    private func showTrade() async -> Bool {
        let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
        let vc = OrcaSwapV2.ViewController(viewModel: vm)

        return await withCheckedContinuation { continuation in
            vc.doneHandler = { [unowned self] in
                navigationController.popToRootViewController(animated: true)
                return continuation.resume(with: .success(true))
            }
            vc.onClose = {
                continuation.resume(with: .success(false))
            }
            navigationController.show(vc, sender: nil)
        }
    }

    private func showAboutSolend(depositVC: UIViewController) {
        let view = AboutSolendView()
        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        depositVC.present(viewController, animated: true)

        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        view.cancel
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
    }
}
