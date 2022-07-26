// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

final class CreateWalletCoordinator: Coordinator<Void> {
    // MARK: - NavigationController

    let tKeyFacade: TKeyJSFacade

    private(set) var navigationController: UINavigationController?

    init(tKeyFacade: TKeyJSFacade) {
        self.tKeyFacade = tKeyFacade
        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        guard navigationController == nil else {
            return Empty()
                .eraseToAnyPublisher()
        }

        // Create root view controller
        let viewModel = CreateWalletViewModel(tKeyFacade: nil)
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
        // Handler final states
        switch viewModel.onboardingStateMachine.currentState {
        case .socialSignIn:
            coordinate(to: SocialSignInCoordinator(parent: navigationController!, createWalletViewModel: viewModel))
            return
        case .finishWithoutResult:
            navigationController?.dismiss(animated: true)
            return
        default:
            break
        }

        guard let navigationController = navigationController else { return }
        let vc = buildViewController(viewModel: viewModel)
        navigationController.setViewControllers([vc], animated: true)
    }

    private func buildViewController(viewModel: CreateWalletViewModel) -> UIViewController {
        let state = viewModel.onboardingStateMachine.currentState
        switch state {
        case .socialSignInUnhandleableError:
            return UIViewController()
        case let .enterPhoneNumber(solPrivateKey, ethPublicKey, deviceShare):
            UserDefaults.standard.set(deviceShare, forKey: "deviceShare")
            return EnterPhoneNumberViewController(sol: solPrivateKey, eth: ethPublicKey, deviceShare: deviceShare)
        case let .verifyPhoneNumber(solPrivateKey, ethPublicKey, deviceShare, phoneNumber):
            return UIViewController()
        case let .enterPincode(solPrivateKey, ethPublicKey, deviceShare, phoneNumberShare: phoneNumberShare):
            return UIViewController()
        default:
            return UIViewController()
        }
    }
}
