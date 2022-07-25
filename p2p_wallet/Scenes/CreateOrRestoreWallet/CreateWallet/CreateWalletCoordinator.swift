// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

final class CreateWalletCoordinator: Coordinator<Void> {
    // MARK: - NavigationController

    private(set) var navigationController: UINavigationController?

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        guard navigationController == nil else {
            return Empty()
                .eraseToAnyPublisher()
        }

        // Create root view controller
        let viewModel = CreateWalletViewModel()
        let viewController = buildViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController?.modalPresentationStyle = .fullScreen

        viewModel.onboardingStateMachine
            .stateStream
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self, unowned viewModel] _ in self?.navigate(viewModel: viewModel) }
            .store(in: &subscriptions)

        return Empty()
            .eraseToAnyPublisher()
    }

    // MARK: Navigation

    private func navigate(viewModel: CreateWalletViewModel) {
        guard let navigationController = navigationController else { return }
        let vc = buildViewController(viewModel: viewModel)
        navigationController.setViewControllers([vc], animated: true)
    }

    private func buildViewController(viewModel: CreateWalletViewModel) -> UIViewController {
        let state = viewModel.onboardingStateMachine.currentState
        switch state {
        case .socialSignIn:
            return SocialSignInViewController(viewModel: viewModel)
        case .socialSignInUnhandleableError:
            return UIViewController()
        case let .enterPhoneNumber(solPrivateKey, ethPublicKey, deviceShare):
            return EnterPhoneNumberViewController(sol: solPrivateKey, eth: ethPublicKey, deviceShare: deviceShare)
        case let .verifyPhoneNumber(solPrivateKey, ethPublicKey, deviceShare, phoneNumber):
            return UIViewController()
        case let .enterPincode(solPrivateKey, ethPublicKey, deviceShare, phoneNumberShare: phoneNumberShare):
            return UIViewController()
        case let .finish(solPrivateKey, ethPublicKey, deviceShare, phoneNumberShare, pincode):
            return UIViewController()
        }
    }
}
