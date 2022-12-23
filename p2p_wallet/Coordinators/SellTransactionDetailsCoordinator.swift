//
//  SellTransactionDetailsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 14.12.2022.
//

import Combine
import Foundation
import UIKit
import Resolver
import Sell

private typealias Result = SellTransactionDetailsCoorditor.Result

final class SellTransactionDetailsCoorditor: Coordinator<SellTransactionDetailsCoorditor.Result> {
    @Injected private var walletsRepository: WalletsRepository
    
    private let viewController: UIViewController
    private let strategy: Strategy
    private let transaction: SellDataServiceTransaction
    private let fiat: Fiat
    private let date: Date

    private let transition = PanelTransition()

    init(
        viewController: UIViewController,
        strategy: Strategy,
        transaction: SellDataServiceTransaction,
        fiat: Fiat,
        date: Date
    ) {
        self.viewController = viewController
        self.strategy = strategy
        self.transaction = transaction
        self.fiat = fiat
        self.date = date
    }

    override func start() -> AnyPublisher<Result, Never> {
        let controller: UIViewController
        let resultSubject: PassthroughSubject<Result, Never>

        switch strategy {
        case .success:
            (controller, resultSubject) = startSuccessCoordinator()
        case let .notSuccess(subStrategy):
            (controller, resultSubject) = startNotSuccessCoordinator(strategy: subStrategy)
        }

        controller.view.layer.cornerRadius = 16
        controller.transitioningDelegate = transition
        controller.modalPresentationStyle = .custom
        viewController.present(controller, animated: true)

        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    private func startSuccessCoordinator() -> (
        UIViewController,
        PassthroughSubject<Result, Never>
    ) {
        let view = SellSuccessTransactionDetailsView(
            model: SellSuccessTransactionDetailsView.Model(
                topViewModel: SellTransactionDetailsTopView.Model(
                    date: date,
                    tokenImage: .solanaIcon,
                    tokenSymbol: "SOL",
                    tokenAmount: transaction.baseCurrencyAmount,
                    fiatAmount: transaction.quoteCurrencyAmount,
                    currency: fiat
                ),
                receiverAddress: "FfRBtrgvrtgefefgrBeJEr",
                transactionFee: L10n.freePaidByKeyApp
            )
        )
        transition.containerHeight = view.viewHeight
        let controller = view.asViewController()

        let resultSubject = PassthroughSubject<Result, Never>()

        transition.dimmClicked
            .sink(receiveValue: {
                controller.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        view.dismiss
            .sink(receiveValue: {
                controller.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        controller.onClose = {
            resultSubject.send(.cancel)
        }

        return (controller, resultSubject)
    }

    private func startNotSuccessCoordinator(strategy: SellTransactionDetailsViewModel.Strategy) -> (
        UIViewController,
        PassthroughSubject<Result, Never>
    ) {
        let viewModel = SellTransactionDetailsViewModel(
            transaction: transaction,
            fiat: fiat,
            strategy: strategy,
            date: date,
            tokenImage: .solanaIcon,
            tokenSymbol: "SOL"
        )
        let view = SellTransactionDetailsView(viewModel: viewModel)
        transition.containerHeight = view.viewHeight
        let controller = view.asViewController()

        let resultSubject = PassthroughSubject<Result, Never>()

        transition.dimmClicked
            .sink(receiveValue: {
                controller.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        viewModel.result
            .sink(receiveValue: { [weak self] result in
                switch result {
                case .send:
                    resultSubject.send(.send)
                case .cancel:
                    controller.dismiss(animated: true)
                case .tryAgain:
                    resultSubject.send(.tryAgain)
                }
            })
            .store(in: &subscriptions)
        controller.onClose = {
            resultSubject.send(.cancel)
        }

        return (controller, resultSubject)
    }
}

// MARK: - Strategy

extension SellTransactionDetailsCoorditor {
    enum Strategy {
        case success
        case notSuccess(SellTransactionDetailsViewModel.Strategy)
    }
}

// MARK: - Result

extension SellTransactionDetailsCoorditor {
    enum Result {
        case cancel
        case send
        case tryAgain
    }
}
