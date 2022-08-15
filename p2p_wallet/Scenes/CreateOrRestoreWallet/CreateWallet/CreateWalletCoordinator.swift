// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import UIKit

enum CreateWalletResult {
    case restore(socialProvider: SocialProvider, email: String)
    case success(OnboardingWallet)
}

final class CreateWalletCoordinator: Coordinator<CreateWalletResult> {
    // MARK: - NavigationController

    private let parentViewController: UIViewController
    private(set) var navigationController: UINavigationController?

    private let tKeyFacade: TKeyJSFacade?
    private let viewModel: CreateWalletViewModel
    private var result = PassthroughSubject<CreateWalletResult, Never>()

    let socialSignInDelegatedCoordinator: SocialSignInDelegatedCoordinator
    let bindingPhoneNumberDelegatedCoordinator: BindingPhoneNumberDelegatedCoordinator
    let securitySetupDelegatedCoordinator: SecuritySetupDelegatedCoordinator

    init(parent: UIViewController, initialState: CreateWalletFlowState? = nil) {
        parentViewController = parent

        // Setup
        tKeyFacade = TKeyJSFacade(
            wkWebView: GlobalWebView.requestWebView(),
            config: .init(
                metadataEndpoint: String.secretConfig("META_DATA_ENDPOINT") ?? "",
                torusEndpoint: String.secretConfig("TORUS_ENDPOINT") ?? "",
                torusVerifierMapping: [
                    "google": String.secretConfig("TORUS_GOOGLE_VERIFIER") ?? "",
                    "apple": String.secretConfig("TORUS_APPLE_VERIFIER") ?? "",
                ]
            )
        )
        viewModel = CreateWalletViewModel(tKeyFacade: tKeyFacade, initialState: initialState)

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

        navigationController = navigationController ?? UINavigationController(rootViewController: viewController)
        navigationController!.modalPresentationStyle = .fullScreen

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

        navigationController?.modalTransitionStyle = .crossDissolve
        parentViewController.present(navigationController!, animated: true)

        return result.eraseToAnyPublisher()
    }

    // MARK: Navigation

    private func stateChangeHandler(from: CreateWalletFlowState?, to: CreateWalletFlowState) {
        if case let .finish(result) = to {
            navigationController?.dismiss(animated: true)
            switch result {
            case let .switchToRestoreFlow(socialProvider, email):
                self.result.send(.restore(socialProvider: socialProvider, email: email))
            case let .newWallet(onboardingWallet):
                self.result.send(.success(onboardingWallet))
            case .breakProcess:
                break
            }
            self.result.send(completion: .finished)
        }

        guard let navigationController = navigationController else { return }

        // TODO: Add empty screen
        let vc = buildViewController(state: to) ?? UIViewController()

        if to.step >= (from?.step ?? -1) {
            navigationController.setViewControllers([vc], animated: true)
        } else {
            navigationController.setViewControllers([vc] + navigationController.viewControllers, animated: false)
            navigationController.popToViewController(vc, animated: true)
        }
    }

    private func buildViewController(state: CreateWalletFlowState) -> UIViewController? {
        print(state)
        switch state {
        case let .socialSignIn(innerState):
            return socialSignInDelegatedCoordinator.buildViewController(for: innerState)
        case let .bindingPhoneNumber(_, _, _, _, innerState):
            return bindingPhoneNumberDelegatedCoordinator.buildViewController(for: innerState)
        case let .securitySetup(_, _, _, _, innerState):
            return securitySetupDelegatedCoordinator.buildViewController(for: innerState)
        default:
            return nil
        }
    }
}
