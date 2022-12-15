//
//  SellTransactionDetailsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 14.12.2022.
//

import Combine
import Foundation
import UIKit

final class SellTransactionDetailsCoorditor: Coordinator<Void> {
    private let viewController: UIViewController

    private let transition = PanelTransition()

    init(
        viewController: UIViewController
    ) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SellSuccessTransactionDetailsView(
            model: SellSuccessTransactionDetailsView.Model(
                topViewModel: SellTransactionDetailsTopView.Model(
                    date: Date(),
                    tokenImage: .usdc,
                    tokenSymbol: "SOL",
                    tokenAmount: 5,
                    fiatAmount: 300.05,
                    currency: .eur
                ),
                receiverAddress: "FfRB...BeJEr",
                transactionFee: L10n.freePaidByKeyApp
            )
        )
        transition.containerHeight = view.viewHeight
        let controller = view.asViewController()
        controller.view.layer.cornerRadius = 16
        controller.transitioningDelegate = transition
        controller.modalPresentationStyle = .custom
        viewController.present(controller, animated: true)

        let resultSubject = PassthroughSubject<Void, Never>()

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
            resultSubject.send()
        }

        return resultSubject.prefix(1).eraseToAnyPublisher()
    }
}

// MARK: - Strategy

extension SellTransactionDetailsCoorditor {
    enum Strategy {
        case success
        case notSuccess(SellTransactionDetailsView.Strategy)
    }
}
