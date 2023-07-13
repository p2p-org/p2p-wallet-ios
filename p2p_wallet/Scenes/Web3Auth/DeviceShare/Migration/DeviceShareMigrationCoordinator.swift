//
//  DeviceShareMigrationCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Combine
import Foundation
import Onboarding
import Resolver
import SwiftUI

enum DeviceShareMigrationCoordinatorResult {
    case finish
    case error(Error)
}

final class DeviceShareMigrationCoordinator: Coordinator<DeviceShareMigrationCoordinatorResult> {
    enum Result {
        case finish
        case error(Error)
    }

    let result = PassthroughSubject<DeviceShareMigrationCoordinatorResult, Never>()
    let navigationController: UINavigationController

    let facade: TKeyFacade

    init(facade: TKeyFacade, navigationController: UINavigationController) {
        self.facade = facade
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<DeviceShareMigrationCoordinatorResult, Never> {
        let vm = DeviceShareMigrationViewModel(facade: facade)
        let view = DeviceShareMigrationView(viewModel: vm)
        let vc = UIHostingController(rootView: view)

        navigationController.pushViewController(vc, animated: true)

        vm.action.sink { [weak self] action in
            switch action {
            case let .error(error):
                self?.navigationController.popViewController(animated: true)
                self?.result.send(.error(error))
            case .finish:
                self?.navigationController.popViewController(animated: true)
                self?.result.send(.finish)
            }
        }.store(in: &subscriptions)

        Task { await vm.start() }

        return result
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
