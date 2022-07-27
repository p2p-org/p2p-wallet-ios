// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import UIKit

final class CreateWalletCoordinator: Coordinator<Void> {
    // MARK: - NavigationController

    private(set) var navigationController: UINavigationController?

    let tKeyFacade: TKeyJSFacade

    private var subject = PassthroughSubject<Void, Never>() // TODO: - Complete this when next navigation is done

    init(tKeyFacade: TKeyJSFacade, navigationController: UINavigationController? = nil) {
        self.tKeyFacade = tKeyFacade
        self.navigationController = navigationController
        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Create root view controller
        let viewModel = CreateWalletViewModel(tKeyFacade: nil)
        let viewController = buildViewController(viewModel: viewModel)
        if navigationController == nil {
            navigationController = UINavigationController(rootViewController: viewController)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
        navigationController?.modalPresentationStyle = .fullScreen

        viewModel.onboardingStateMachine
            .stateStream
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self, unowned viewModel] _ in self?.navigate(viewModel: viewModel) }
            .store(in: &subscriptions)

        return subject
            .eraseToAnyPublisher()
    }

    // MARK: Navigation

    private func navigate(viewModel: CreateWalletViewModel) {
        // Handler final states
        switch viewModel.onboardingStateMachine.currentState {
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
        case .socialSignIn:
            return SocialSignInViewController(viewModel: .init(createWalletViewModel: viewModel))
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
