//
//  SwapSettingsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 01.03.2023.
//

import Combine
import Foundation
import UIKit

final class SwapSettingsCoordinator: Coordinator<Double?> {
    private let navigationController: UINavigationController
    private let slippage: Double
    private var result = PassthroughSubject<Double?, Never>()

    init(navigationController: UINavigationController, slippage: Double) {
        self.navigationController = navigationController
        self.slippage = slippage
    }

    override func start() -> AnyPublisher<Double?, Never> {
        let viewModel = SwapSettingsViewModel(slippage: slippage)
        let view = SwapSettingsView(viewModel: viewModel)
        let viewController = view.asViewController(withoutUIKitNavBar: false)
        viewController.title = L10n.swapDetails
        navigationController.pushViewController(viewController, animated: true)
        viewController.deallocatedPublisher()
            .sink(receiveValue: { [weak self] in
                self?.result.send(viewModel.finalSlippage)
            })
            .store(in: &subscriptions)
        
        return result.prefix(1).eraseToAnyPublisher()
    }
}
