// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import KeyAppUI
import Onboarding
import UIKit
import AnalyticsManager
import Resolver

enum CreateWalletResult {
    case restore(socialProvider: SocialProvider, email: String)
    case success(CreateWalletData)
    case breakProcess
}

final class CreateWalletCoordinator: Coordinator<CreateWalletResult> {

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - NavigationController

    private let parent: UIViewController
    private let navigationController: OnboardingNavigationController

    private let viewModel: CreateWalletViewModel
    private var result = PassthroughSubject<CreateWalletResult, Never>()

    let socialSignInDelegatedCoordinator: SocialSignInDelegatedCoordinator
    let bindingPhoneNumberDelegatedCoordinator: BindingPhoneNumberDelegatedCoordinator
    let securitySetupDelegatedCoordinator: SecuritySetupDelegatedCoordinator

    var animated: Bool = true

    init(
        parent: UIViewController,
        navigationController: OnboardingNavigationController,
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
                do {
                    try await viewModel?.onboardingStateMachine.accept(event: .socialSignInEvent(event))
                } catch {
                    Self.log(error: error)
                    throw error
                }
            }
        )

        bindingPhoneNumberDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                do {
                    try await viewModel?.onboardingStateMachine.accept(event: .bindingPhoneNumberEvent(event))
                } catch {
                    Self.log(error: error)
                    throw error
                }
            }
        )

        securitySetupDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                do {
                    try await viewModel?.onboardingStateMachine.accept(event: .securitySetup(event))
                } catch {
                    Self.log(error: error)
                    throw error
                }
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
                navigationController.fadeTo(vc)
            } else {
                navigationController.setViewControllers([vc], animated: true)
            }
        } else {
            if let from = from, case .socialSignIn(.socialSignInProgress) = from {
                navigationController.fadeOut(vc)
            } else {
                navigationController.setViewControllers([vc] + navigationController.viewControllers, animated: false)
                navigationController.popToViewController(vc, animated: true)
            }
        }
        displayIntermediateToastIfNeeded(from: from, to: to)
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
            logOpenSecurity(state: innerState)
            return vc
        default:
            return nil
        }
    }

    private func displayIntermediateToastIfNeeded(from: CreateWalletFlowState?, to: CreateWalletFlowState) {
        guard case .bindingPhoneNumber = from, case .securitySetup = to else { return }
        SnackBar(
            title: "🎉",
            text: L10n.yourWalletHasBeenCreatedJustAFewMomentsToStartACryptoAdventure
        ).show(in: navigationController.view)
    }

    private static func log(error: Error) {
        switch error {
            case SocialServiceError.cancelled:
                return
            default:
            break
        }

        Task {
            let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)
            DefaultLogManager.shared.log(
                event: "Web3 Registration iOS Alarm",
                logLevel: .alert,
                data: CreateWalletAlertLoggerErrorMessage(
                    error: error.readableDescription,
                    userPubKey: data.userPubkey
                )
            )
        }
    }
}

private extension CreateWalletCoordinator {
    func logOpenSecurity(state: SecuritySetupState) {
        switch state {
        case .createPincode:
            analyticsManager.log(event: .createConfirmPinScreenOpened)
        case .confirmPincode:
            analyticsManager.log(event: .createConfirmPinFirstClick)
        case .finish:
            break
        }
    }
}
