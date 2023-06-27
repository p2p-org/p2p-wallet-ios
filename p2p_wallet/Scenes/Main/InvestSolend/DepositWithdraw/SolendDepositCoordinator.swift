// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Resolver
import Solend
import SwiftUI
import UIKit

final class SolendDepositCoordinator: Coordinator<Bool> {
    private let controller: UINavigationController
    private let transition = PanelTransition()

    let initialAsset: SolendConfigAsset
    let initialStrategy: DepositSolendViewModel.Strategy

    init(
        controller: UINavigationController,
        initialAsset: SolendConfigAsset,
        initialStrategy: DepositSolendViewModel.Strategy
    ) {
        self.controller = controller
        self.initialAsset = initialAsset
        self.initialStrategy = initialStrategy
        super.init()
    }

    override func start() -> AnyPublisher<Bool, Never> {
        let resultSubject = PassthroughSubject<Bool, Never>()

        let viewModel = try! DepositSolendViewModel(strategy: initialStrategy, initialAsset: initialAsset)
        viewModel.finish.sink { [unowned self] in
            controller.popViewController(animated: true)
            resultSubject.send(true)
            resultSubject.send(completion: .finished)
        }.store(in: &subscriptions)

        let view = DepositSolendView(viewModel: viewModel)
        let depositVC = view.asViewController(withoutUIKitNavBar: false)
        controller.pushViewController(
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

        depositVC.onClose = {
            resultSubject.send(completion: .finished)
        }

        return resultSubject.eraseToAnyPublisher()
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
