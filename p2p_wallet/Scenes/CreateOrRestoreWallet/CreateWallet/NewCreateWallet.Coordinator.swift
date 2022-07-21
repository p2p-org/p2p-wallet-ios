// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

extension NewCreateWallet {
    final class Coordinator: p2p_wallet.Coordinator<Void> {
        // MARK: - NavigationController

        private(set) var navigationController: UINavigationController?
        private let viewModel: NewCreateWallet.ViewModel

        // MARK: - Initializer

        init(viewModel: NewCreateWallet.ViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - Methods

        override func start() -> AnyPublisher<Void, Error> {
            guard navigationController == nil else {
                return Fail(error: CoordinatorError.isAlreadyStarted)
                    .eraseToAnyPublisher()
            }

            // Create root view controller
            let viewController = buildViewController(state: viewModel.onboardingStateMachine.currentState)
            navigationController = UINavigationController(rootViewController: viewController)
            navigationController?.modalPresentationStyle = .fullScreen

            viewModel.onboardingStateMachine
                .stateStream
                .dropFirst()
                .receive(on: RunLoop.main)
                .sink { [weak self] state in self?.navigate(to: state) }
                .store(in: &subscriptions)

            return Empty()
                .eraseToAnyPublisher()
        }

        // MARK: Navigation

        private func navigate(to state: CreateWalletState) {
            guard let navigationController = navigationController else { return }
            let vc = buildViewController(state: state)
            navigationController.setViewControllers([vc], animated: true)
        }

        private func buildViewController(state: CreateWalletState) -> UIViewController {
            switch state {
            case .socialSignIn:
                return SocialSignIn.ViewController(viewModel: viewModel)
            case .socialSignInUnhandleableError:
                return UIViewController()
            case let .enterPhoneNumber(solPrivateKey, ethPublicKey, deviceShare):
                return EnterPhoneNumber.ViewController(sol: solPrivateKey, eth: ethPublicKey, deviceShare: deviceShare)
            case let .verifyPhoneNumber(solPrivateKey, ethPublicKey, deviceShare, phoneNumber):
                return UIViewController()
            case let .enterPincode(solPrivateKey, ethPublicKey, deviceShare, phoneNumberShare: phoneNumberShare):
                return UIViewController()
            case let .finish(solPrivateKey, ethPublicKey, deviceShare, phoneNumberShare, pincode):
                return UIViewController()
            }
        }
    }
}
