// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

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

        return Empty()
            .eraseToAnyPublisher()
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
        case .signIn:
            return RestoreFlowsViewController(viewModel: viewModel)
        case let .restoredData(solPrivateKey: solPrivateKey, ethPublicKey: ethPublicKey):
            return RestoreResultViewController(sol: solPrivateKey, eth: ethPublicKey)
        }
    }
}
