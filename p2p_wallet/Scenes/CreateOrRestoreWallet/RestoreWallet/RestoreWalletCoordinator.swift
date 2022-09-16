// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import KeyAppUI
import Onboarding
import SwiftUI

enum RestoreWalletNavigation {
    case root(window: UIWindow)
    case child(parent: UIViewController, navigationController: UINavigationController)
}

final class RestoreWalletCoordinator: Coordinator<OnboardingResult> {
    private let navigationController: UINavigationController
    private let navigation: RestoreWalletNavigation

    private let viewModel: RestoreWalletViewModel
    private var result = PassthroughSubject<OnboardingResult, Never>()

    private let securitySetupDelegatedCoordinator: SecuritySetupDelegatedCoordinator
    private let restoreCustomDelegatedCoordinator: RestoreCustomDelegatedCoordinator
    private let restoreSocialDelegatedCoordinator: RestoreSocialDelegatedCoordinator
    private let restoreSeedDelegatedCoordinator: RestoreSeedPhraseDelegatedCoordinator
    private let restoreICloudDelegatedCoordinator: RestoreICloudDelegatedCoordinator

    init(navigation: RestoreWalletNavigation) {
        switch navigation {
        case .root:
            navigationController = UINavigationController()
        case let .child(_, navigationController):
            self.navigationController = navigationController
        }
        self.navigation = navigation
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve

        viewModel = RestoreWalletViewModel()

        securitySetupDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.stateMachine.accept(event: .securitySetup(event))
            }
        )

        restoreCustomDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.stateMachine.accept(event: .restoreCustom(event))
            }
        )

        restoreSocialDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.stateMachine.accept(event: .restoreSocial(event))
            }
        )

        restoreSeedDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.stateMachine.accept(event: .restoreSeed(event))
            }
        )

        restoreICloudDelegatedCoordinator = .init(
            stateMachine: .init { [weak viewModel] event in
                try await viewModel?.stateMachine.accept(event: .restoreICloud(event))
            }
        )

        super.init()
        setDelegatedCoordinatorRoot()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<OnboardingResult, Never> {
        guard let viewController = buildViewController(state: viewModel.stateMachine.currentState) else {
            return Empty().eraseToAnyPublisher()
        }

        navigationController.setViewControllers([viewController], animated: true)
        switch navigation {
        case let .root(window):
            window.animate(newRootViewController: navigationController)
        case let .child(parent, navigationController):
            if navigationController.presentingViewController == nil {
                parent.present(navigationController, animated: true)
            }
        }

        viewModel.stateMachine
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

    private func setDelegatedCoordinatorRoot() {
        restoreCustomDelegatedCoordinator.rootViewController = navigationController
        securitySetupDelegatedCoordinator.rootViewController = navigationController
        restoreSocialDelegatedCoordinator.rootViewController = navigationController
        restoreSeedDelegatedCoordinator.rootViewController = navigationController
        restoreICloudDelegatedCoordinator.rootViewController = navigationController
    }

    private func stateChangeHandler(from: RestoreWalletState?, to: RestoreWalletState) {
        if case let .finished(result) = to {
            switch result {
            case let .successful(wallet):
                self.result.send(.restored(wallet))
            case .breakProcess:
                self.result.send(.breakProcess)
                switch navigation {
                case .root: break
                case .child: self.navigationController.dismiss(animated: true)
                }
            }
            self.result.send(completion: .finished)

            return
        }

        // TODO: Add empty screen
        let vc = buildViewController(state: to) ?? UIViewController()

        if to.step >= (from?.step ?? -1) {
            navigationController.setViewControllers([vc], animated: true)
        } else {
            navigationController.setViewControllers([vc] + navigationController.viewControllers, animated: false)
            navigationController.popToViewController(vc, animated: true)
        }
    }

    private func buildViewController(state: RestoreWalletState) -> UIViewController? {
        switch state {
        case .restore:
            let params = ChooseRestoreOptionParameters(
                isBackAvailable: isBackAvailable(),
                content: OnboardingContentData(image: .lockPincode, title: L10n.chooseTheWayToContinue),
                options: viewModel.availableRestoreOptions,
                isStartAvailable: false
            )
            return buildRestoreScreen(parameters: params)

        case let .restoreICloud(innerState):
            return restoreICloudDelegatedCoordinator.buildViewController(for: innerState)

        case let .restoreSocial(innerState, _):
            return restoreSocialDelegatedCoordinator.buildViewController(for: innerState)

        case let .restoreCustom(innerState):
            return restoreCustomDelegatedCoordinator.buildViewController(for: innerState)

        case let .restoreSeed(innerState):
            return restoreSeedDelegatedCoordinator.buildViewController(for: innerState)

        case let .securitySetup(_, _, innerState):
            let vc = securitySetupDelegatedCoordinator.buildViewController(for: innerState)
            vc?.title = ""
            return vc

        case .finished:
            return nil
        }
    }

    private func openTerms() {
        let termsVC = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        navigationController.present(termsVC, animated: true)
    }

    @objc private func openInfo() {
        openTerms()
    }

    private func isBackAvailable() -> Bool {
        switch navigation {
        case .root:
            return false
        case .child:
            return true
        }
    }
}

private extension RestoreWalletCoordinator {
    func buildRestoreScreen(parameters: ChooseRestoreOptionParameters) -> UIViewController {
        var stateMachine = viewModel.stateMachine
        let chooseRestoreOptionViewModel = ChooseRestoreOptionViewModel(parameters: parameters)
        chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { process in
            process.start {
                switch process.data {
                case .keychain:
                    _ = try await stateMachine <- .restoreICloud(.signIn)
                case .custom:
                    _ = try await stateMachine <- .restoreCustom(.enterPhone)
                case .socialApple:
                    _ = try await stateMachine <- .restoreSocial(.signInDevice(socialProvider: .apple))
                case .socialGoogle:
                    _ = try await stateMachine <- .restoreSocial(.signInDevice(socialProvider: .google))
                case .seed:
                    _ = try await stateMachine <- .restoreSeed(.signInWithSeed)
                default: break
                }
            }
        })
            .store(in: &subscriptions)
        chooseRestoreOptionViewModel.openStart.sinkAsync {
            _ = try await stateMachine <- .start
        }
        .store(in: &subscriptions)
        chooseRestoreOptionViewModel.openInfo.sink { [weak self] in
            self?.openInfo()
        }
        .store(in: &subscriptions)
        chooseRestoreOptionViewModel.back.sinkAsync {
            _ = try await stateMachine <- .back
        }
        .store(in: &subscriptions)
        return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: chooseRestoreOptionViewModel))
    }
}
