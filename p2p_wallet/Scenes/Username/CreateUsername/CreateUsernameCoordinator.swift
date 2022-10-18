// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import Combine
import KeyAppUI
import NameService
import SwiftUI
import UIKit

enum NavigationOption {
    case onboarding(window: UIWindow)
    case settings(parent: UINavigationController)
}

final class CreateUsernameCoordinator: Coordinator<Void> {
    private let navigationOption: NavigationOption
    private var subject = PassthroughSubject<Void, Never>()

    init(navigationOption: NavigationOption) {
        self.navigationOption = navigationOption
    }

    override func start() -> AnyPublisher<Void, Never> {
        let parameters: CreateUsernameParameters
        switch navigationOption {
        case .onboarding:
            parameters = .init(
                isSkipEnabled: available(.onboardingUsernameButtonSkipEnabled),
                backgroundColor: Asset.Colors.lime.color
            )
        case .settings:
            parameters = .init(isSkipEnabled: false, backgroundColor: Asset.Colors.rain.color)
        }

        let viewModel = CreateUsernameViewModel(parameters: parameters)
        let view = CreateUsernameView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        switch navigationOption {
        case let .onboarding(window):
            let navigationController = UINavigationController()
            navigationController.setViewControllers([controller], animated: true)
            window.animate(newRootViewController: navigationController)
        case let .settings(parent):
            controller.hidesBottomBarWhenPushed = true
            parent.pushViewController(controller, animated: true)
        }

        viewModel.requireSkip.sink { [unowned self] in
            self.subject.send(())
            self.subject.send(completion: .finished)
        }.store(in: &subscriptions)

        viewModel.transactionCreated.sink { [weak self] in
            self?.subject.send(())
            self?.subject.send(completion: .finished)
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }
}
