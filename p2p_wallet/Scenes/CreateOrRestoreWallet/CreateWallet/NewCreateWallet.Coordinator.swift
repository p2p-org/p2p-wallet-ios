// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

extension NewCreateWallet {
    final class Coordinator: AbstractCoordinator {
        private var navigationController: UINavigationController?
        public let viewModel: ViewModel

        private var disposeBag: Set<AnyCancellable> = .init()

        init(viewModel: ViewModel) {
            self.viewModel = viewModel
        }

        func submitEvent(event: CreateWalletState.Event) async throws -> CreateWalletState {
            try await viewModel.onboardingStateMachine.accept(event: event)
        }

        func start(_: ((Any) -> Void)?) throws -> UIViewController {
            guard navigationController == nil else { throw CoordinatorError.isAlreadyStarted }

            // Create root view controller
            let viewController = buildViewController(state: viewModel.onboardingStateMachine.currentState)
            navigationController = UINavigationController(rootViewController: viewController)
            navigationController?.modalPresentationStyle = .fullScreen

            // Subscribe to state changing
            viewModel
                .onboardingStateMachine
                .stateStream
                .dropFirst()
                .receive(on: RunLoop.main)
                .sink { [weak self] state in self?.navigate(to: state) }
                .store(in: &disposeBag)

            return navigationController!
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
                return SocialSignIn.ViewController(coordinator: self)
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
