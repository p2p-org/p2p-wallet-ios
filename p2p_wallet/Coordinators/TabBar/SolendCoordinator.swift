//
//  SolendCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 02.10.2022.
//

import Combine
import Foundation
import UIKit
import SolanaSwift

final class SolendCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        guard available(.solendDisablePlaceholder) else {
            return startPlaceholder()
        }

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
            .sink { [unowned self] in
                coordinate(to: SolendDepositCoordinator(
                    controller: navigationController, initialAsset: $0,
                    initialStrategy: .deposit
                ))
                .sink { _ in }
                .store(in: &subscriptions)
            }
            .store(in: &subscriptions)

        investViewModel.withdraw
            .sink { [unowned self] in
                coordinate(to: SolendDepositCoordinator(
                    controller: navigationController, initialAsset: $0,
                    initialStrategy: .withdraw
                ))
                .sink { _ in }
                .store(in: &subscriptions)
            }
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

    private func startPlaceholder() -> AnyPublisher<Void, Never> {
        let placeholderVC = SolendPlaceholderView().asViewController(withoutUIKitNavBar: false)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationItem.largeTitleDisplayMode = .always
        navigationController.setViewControllers([placeholderVC], animated: false)
        return Empty(completeImmediately: false)
            .eraseToAnyPublisher()
    }

    private func showBuy(symbol: String) {
        // Preparing params for buy view model
        var defaultToken: Token?
        var targetSymbol: String?
        switch symbol {
        case "USDC": defaultToken = Token.usdc
        case "SOL": defaultToken = Token.nativeSolana
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
        let viewController = view.asViewController()
        viewController.view.layer.cornerRadius = 16
        viewController.modalPresentationStyle = .custom
        depositVC.present(viewController, animated: true)

        view.cancel
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
    }
}
