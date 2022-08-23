// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import KeyAppUI
import Onboarding
import SwiftUI

enum RestoreWalletResult {
    case start
    case help
    case success(OnboardingWallet)
}

final class RestoreWalletCoordinator: Coordinator<RestoreWalletResult> {
    let parent: UIViewController
    let tKeyFacade: TKeyJSFacade = .init(
        wkWebView: GlobalWebView.requestWebView(),
        config: .init(
            metadataEndpoint: String.secretConfig("META_DATA_ENDPOINT") ?? "",
            torusEndpoint: String.secretConfig("TORUS_ENDPOINT") ?? "",
            torusNetwork: "testnet",
            torusVerifierMapping: [
                "google": String.secretConfig("TORUS_GOOGLE_VERIFIER") ?? "",
                "apple": String.secretConfig("TORUS_APPLE_VERIFIER") ?? "",
            ]
        )
    )

    let viewModel: RestoreWalletViewModel

    private var result = PassthroughSubject<RestoreWalletResult, Never>()
    private(set) var navigationController: UINavigationController?

    let securitySetupDelegatedCoordinator: SecuritySetupDelegatedCoordinator
    let restoreCustomDelegatedCoordinator: RestoreCustomDelegatedCoordinator
    let restoreSocialDelegatedCoordinator: RestoreSocialDelegatedCoordinator

    init(parent: UIViewController) {
        self.parent = parent
        viewModel = RestoreWalletViewModel(tKeyFacade: tKeyFacade)

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

        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<RestoreWalletResult, Never> {
        guard let viewController = buildViewController(state: viewModel.stateMachine.currentState) else {
            return Empty().eraseToAnyPublisher()
        }

        navigationController = UINavigationController(rootViewController: viewController)
        navigationController?.modalPresentationStyle = .fullScreen
        navigationController?.modalTransitionStyle = .crossDissolve

        restoreCustomDelegatedCoordinator.rootViewController = navigationController
        securitySetupDelegatedCoordinator.rootViewController = navigationController

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

        parent.present(navigationController!, animated: true)

        return result.eraseToAnyPublisher()
    }

    // MARK: Navigation

    private func stateChangeHandler(from: RestoreWalletState?, to: RestoreWalletState) {
        if case let .finished(result) = to {
            switch result {
            case let .successful(wallet):
                self.result.send(.success(wallet))
            case .breakProcess:
                self.result.send(.start)
            case .needHelp:
                self.result.send(.help)
            }
            navigationController?.dismiss(animated: true)
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

    private func buildViewController(state: RestoreWalletState) -> UIViewController? {
        var stateMachine = viewModel.stateMachine
        switch state {
        case .restore:
            let chooseRestoreOptionViewModel = ChooseRestoreOptionViewModel(options: viewModel
                .availableRestoreOptions)
            chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { process in
                process.start {
                    switch process.data {
                    case .keychain:
                        _ = try await stateMachine <- .signInWithKeychain
                    case .custom:
                        _ = try await stateMachine <- .restoreCustom(.enterPhone)
                    case .socialApple:
                        _ = try await stateMachine <- .restoreSocial(.signInDevice(socialProvider: .apple))
                    case .socialGoogle:
                        _ = try await stateMachine <- .restoreSocial(.signInDevice(socialProvider: .google))
                    case .seed:
                        _ = try await stateMachine <- .signInWithSeed
                    default: break
                    }
                }
            })
                .store(in: &subscriptions)
            chooseRestoreOptionViewModel.back.sinkAsync {
                _ = try await stateMachine <- .back
            }
            .store(in: &subscriptions)
            chooseRestoreOptionViewModel.openInfo.sink { [weak self] in
                self?.openInfo()
            }
            .store(in: &subscriptions)
            return UIHostingController(rootView: ChooseRestoreOptionView(viewModel: chooseRestoreOptionViewModel))

        case let .signInKeychain(accounts):
            let vm = ICloudRestoreViewModel(accounts: accounts)

            vm.coordinatorIO.back.sink { process in
                process.start { _ = try await stateMachine <- .back }
            }.store(in: &subscriptions)

            vm.coordinatorIO.info.sink { [weak self] process in
                process.start { self?.openTerms() }
            }.store(in: &subscriptions)

            vm.coordinatorIO.restore.sink { process in
                process.start {
                    _ = try await stateMachine <- .restoreICloudAccount(account: process.data)
                }
            }.store(in: &subscriptions)

            return UIHostingController(rootView: ICloudRestoreScreen(viewModel: vm))
        case .signInSeed:
            fatalError()

        case let .restoreSocial(innerState, _):
            return restoreSocialDelegatedCoordinator.buildViewController(for: innerState)

        case let .restoreCustom(innerState):
            return restoreCustomDelegatedCoordinator.buildViewController(for: innerState)

        case let .securitySetup(_, _, _, _, innerState):
            return securitySetupDelegatedCoordinator.buildViewController(for: innerState)

        case .finished:
            return nil
        }
    }

    private func openTerms() {
        let termsVC = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        navigationController?.present(termsVC, animated: true)
    }

    @objc private func openInfo() {
        openTerms()
    }
}
