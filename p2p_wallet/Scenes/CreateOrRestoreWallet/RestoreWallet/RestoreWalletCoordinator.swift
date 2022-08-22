// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import SwiftUI

final class RestoreWalletCoordinator: Coordinator<Void> {
    // MARK: - NavigationController

    let parent: UIViewController
    let tKeyFacade: TKeyJSFacade = .init(
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

    let viewModel: RestoreWalletViewModel

    private var result = PassthroughSubject<Void, Never>()
    private(set) var navigationController: UINavigationController?

    let securitySetupDelegatedCoordinator: SecuritySetupDelegatedCoordinator
    let restoreCustomDelegatedCoordinator: RestoreCustomDelegatedCoordinator

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

        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
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
        if case let .restoredData(solPrivateKey, ethPublicKey) = to {
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
            chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { [weak self] option in
                guard let self = self else { return }
                switch option {
                case .keychain:
                    try await stateMachine <- .signInWithKeychain
                case .custom:
                    try await stateMachine <- .restoreCustom(.enterPhone)
                case .socialApple:
                    try await stateMachine <-
                        .restoreSocial(.signIn(socialProvider: .apple, deviceShare: self.viewModel.deviceShare!))
                case .socialGoogle:
                    try await stateMachine <-
                        .restoreSocial(.signIn(socialProvider: .google, deviceShare: self.viewModel.deviceShare!))
                case .seed:
                    try await stateMachine <- .signInWithSeed
                default:
                    break
                }
            })
                .store(in: &subscriptions)
            let view = ChooseRestoreOptionView(viewModel: chooseRestoreOptionViewModel)
            return UIHostingController(rootView: view)
        case let .signInKeychain(accounts):
            let vm = ICloudRestoreViewModel(accounts: accounts)

            vm.coordinatorIO.back.sink { process in
                process.start { try await stateMachine <- .back }
            }.store(in: &subscriptions)

            vm.coordinatorIO.info.sink { _ in
                // TODO: show info screen
            }.store(in: &subscriptions)

            vm.coordinatorIO.restore.sink { process in
                process.start {
                    try await stateMachine <- .restoreICloudAccount(account: process.data)
                }
            }.store(in: &subscriptions)

            return UIHostingController(rootView: ICloudRestoreScreen(viewModel: vm))
        case .signInSeed:
            fatalError()
        case let .restoreSocial(_, option):
            switch option {
            case let .first(socialProvider, deviceShare):
                fatalError()
            case let .second(result):
                fatalError()
            }
        case let .restoreCustom(innerState):
            return restoreCustomDelegatedCoordinator.buildViewController(for: innerState)
        case let .securitySetup(_, _, _, _, innerState):
            return securitySetupDelegatedCoordinator.buildViewController(for: innerState)
        case let .restoredData(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey):
            fatalError()
        }
    }
}
