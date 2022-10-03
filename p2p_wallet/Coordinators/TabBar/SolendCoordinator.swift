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
                let view = DepositSolendView(viewModel: viewModel)
                let depositVC = view.asViewController(withoutUIKitNavBar: false)
                navigationController.pushViewController(
                    depositVC,
                    animated: true
                )

                viewModel.transactionDetails
                    .flatMap { [unowned self] in
                        let coordinator = SolendTransactionDetailsCoordinator(
                            controller: depositVC,
                            model: $0
                        )
                        return self.coordinate(to: coordinator)
                    }
                    .sink(receiveValue: { _ in })
                    .store(in: &subscriptions)

                viewModel.tokenSelect.flatMap { [unowned self] tokens in
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
                .sink(receiveValue: { _ in })
                .store(in: &subscriptions)
            })
            .store(in: &subscriptions)

        investViewModel.topUpForContinue
            .sink(receiveValue: { [unowned self] in
                let coordinator = SolendTopUpForContinueCoordinator(
                    navigationController: navigationController,
                    model: $0
                )
                coordinate(to: coordinator)
                    .sink(receiveValue: { [weak self] result in
                        guard
                            let self = self,
                            result == .showTrade
                        else { return }
                        Task {
                            do {
                                let done = await self.showTrade()
                                if done {
                                    self.navigationController.dismiss(animated: true)
                                }
                            }
                        }
                    })
                    .store(in: &subscriptions)
            })
            .store(in: &subscriptions)

        return Empty(completeImmediately: false)
            .eraseToAnyPublisher()
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
}
