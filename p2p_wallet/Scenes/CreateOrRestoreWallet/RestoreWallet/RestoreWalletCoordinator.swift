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
    lazy var tKeyFacade: TKeyJSFacade = .init(
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

    private var result = PassthroughSubject<Void, Never>()
    private(set) var navigationController: UINavigationController?

    init(parent: UIViewController) {
        self.parent = parent
        super.init()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Create root view controller
        let viewModel = RestoreWalletViewModel(tKeyFacade: tKeyFacade)
        let viewController = buildViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController?.modalPresentationStyle = .fullScreen

        viewModel.stateMachine
            .stateStream
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self, unowned viewModel] _ in self?.navigate(viewModel: viewModel) }
            .store(in: &subscriptions)

        parent.present(navigationController!, animated: true)

        return result.eraseToAnyPublisher()
    }

    // MARK: Navigation

    private func navigate(viewModel: RestoreWalletViewModel) {
        guard let navigationController = navigationController else { return }
        let vc = buildViewController(viewModel: viewModel)
        navigationController.setViewControllers([vc], animated: true)
    }

    private func buildViewController(viewModel: RestoreWalletViewModel) -> UIViewController {
        let state = viewModel.stateMachine.currentState
        switch state {
        case .restore:
            let chooseRestoreOptionViewModel = ChooseRestoreOptionViewModel(options: viewModel
                .availableRestoreOptions)
            chooseRestoreOptionViewModel.optionChosen.sinkAsync(receiveValue: { option in
                var stateMachine = viewModel.stateMachine
                switch option {
                case .keychain:
                    try await stateMachine <- .signInWithKeychain
                default:
                    break
                }
            })
                .store(in: &subscriptions)
            let view = ChooseRestoreOptionView(viewModel: chooseRestoreOptionViewModel)
            return UIHostingController(rootView: view)
        case let .securitySetup(email, solPrivateKey, ethPublicKey, deviceShare, innerState):
            fatalError()
        case let .restoredData(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey):
            return RestoreResultViewController(sol: solPrivateKey, eth: ethPublicKey)
        case .signInKeychain:
            fatalError()
        case .signInSeed:
            fatalError()
        case .enterPhone:
            fatalError()
        case let .enterOTP(phoneNumber: phoneNumber):
            fatalError()
        case let .social(result: result):
            fatalError()
        }
    }
}
