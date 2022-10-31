// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import UIKit

enum CreateWalletResult {
    case restore(socialProvider: SocialProvider, email: String)
    case success(CreateWalletData)
    case breakProcess
}

final class CreateWalletCoordinator: Coordinator<CreateWalletResult> {
    // MARK: - NavigationController

    private let parent: UIViewController
    private let navigationController: UINavigationController

    private let viewModel: CreateWalletViewModel
    private var result = PassthroughSubject<CreateWalletResult, Never>()

    let socialSignInDelegatedCoordinator: SocialSignInDelegatedCoordinator
    let bindingPhoneNumberDelegatedCoordinator: BindingPhoneNumberDelegatedCoordinator
    let securitySetupDelegatedCoordinator: SecuritySetupDelegatedCoordinator

    var animated: Bool = true

    init(
        parent: UIViewController,
        navigationController: UINavigationController,
        initialState: CreateWalletFlowState? = nil,
        animated: Bool = true
    ) {
        self.parent = parent
        self.navigationController = navigationController
        self.animated = animated

        // Setup
        viewModel = CreateWalletViewModel(initialState: initialState)

        socialSignInDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.onboardingStateMachine.accept(event: .socialSignInEvent(event))
            }
        )

        bindingPhoneNumberDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.onboardingStateMachine.accept(event: .bindingPhoneNumberEvent(event))
            }
        )

        securitySetupDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.onboardingStateMachine.accept(event: .securitySetup(event))
            }
        )

        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<CreateWalletResult, Never> {
        // Create root view controller
        guard let viewController = buildViewController(state: viewModel.onboardingStateMachine.currentState) else {
            return Empty().eraseToAnyPublisher()
        }

        navigationController.setViewControllers([viewController], animated: animated)
        if parent.presentedViewController == nil {
            parent.present(navigationController, animated: animated)
        }

        socialSignInDelegatedCoordinator.rootViewController = navigationController
        bindingPhoneNumberDelegatedCoordinator.rootViewController = navigationController
        securitySetupDelegatedCoordinator.rootViewController = navigationController

        viewModel.onboardingStateMachine
            .stateStream
            .removeDuplicates()
            .dropFirst()
            .pairwise()
            .receive(on: RunLoop.main)
            .sink { [weak self] pairwise in
                self?.stateChangeHandler(from: pairwise.previous, to: pairwise.current)
            }
            .store(in: &subscriptions)

        return result.eraseToAnyPublisher()
    }

    // MARK: Navigation

    private func stateChangeHandler(from: CreateWalletFlowState?, to: CreateWalletFlowState) {
        if case let .finish(result) = to {
            switch result {
            case let .switchToRestoreFlow(socialProvider, email):
                self.result.send(.restore(socialProvider: socialProvider, email: email))
            case let .newWallet(onboardingWallet):
                self.result.send(.success(onboardingWallet))
            case .breakProcess:
                self.result.send(.breakProcess)
                self.navigationController.dismiss(animated: true)
            }
            self.result.send(completion: .finished)

            return
        }

        // TODO: Add empty screen
        let vc = buildViewController(state: to) ?? UIViewController()

        if to.step >= (from?.step ?? -1) {
            if case .socialSignIn(.socialSignInProgress) = to {
                fadeTo(vc)
            }
            else {
                navigationController.setViewControllers([vc], animated: true)
            }
        } else {
            if let from = from, case .socialSignIn(.socialSignInProgress) = from {
                fadeOut(vc)
            }
            else {
                navigationController.setViewControllers([vc] + navigationController.viewControllers, animated: false)
                navigationController.popToViewController(vc, animated: true)
            }
        }
    }

    private func buildViewController(state: CreateWalletFlowState) -> UIViewController? {
        switch state {
        case let .socialSignIn(innerState):
            return socialSignInDelegatedCoordinator.buildViewController(for: innerState)
        case let .bindingPhoneNumber(_, _, _, _, _, innerState):
            return bindingPhoneNumberDelegatedCoordinator.buildViewController(for: innerState)
        case let .securitySetup(_, _, _, _, innerState):
            let vc = securitySetupDelegatedCoordinator.buildViewController(for: innerState)
            vc?.title = L10n.stepOf("3", "3")
            return vc
        default:
            return nil
        }
    }
}

private extension CreateWalletCoordinator {
    func fadeTo(_ viewController: UIViewController) {
        let transition: CATransition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.fade
        navigationController.view.layer.add(transition, forKey: nil)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func fadeOut(_ viewController: UIViewController) {
        let transition: CATransition = CATransition()
        transition.duration = 0.3
        transition.type = CATransitionType.fade
        navigationController.view.layer.add(transition, forKey: nil)
        navigationController.setViewControllers([viewController] + navigationController.viewControllers, animated: false)
        navigationController.popToViewController(viewController, animated: false)
    }
}
