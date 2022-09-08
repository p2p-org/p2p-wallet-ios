//
//  NetworkCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 31.08.2022.
//

import Combine
import Foundation
import UIKit

final class NetworkCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    private let transition = PanelTransition()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = NetworkViewModel()
        let viewController = NetworkView(viewModel: viewModel).asViewController()
        transition.containerHeight = 432
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        navigationController.present(viewController, animated: true)

        viewModel.dismiss
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)
        transition.dimmClicked
            .sink(receiveValue: {
                viewController.dismiss(animated: true)
            })
            .store(in: &subscriptions)

        let cancelSubject = PassthroughSubject<Void, Never>()
        viewController.onClose = {
            cancelSubject.send()
        }
        return cancelSubject.eraseToAnyPublisher()
    }
}
