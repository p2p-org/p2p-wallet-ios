// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import UIKit

final class CreateWalletCoordinator: Coordinator<Void> {
    // MARK: - NavigationController

    private let parentViewController: UIViewController
    private(set) var navigationController: UINavigationController?

    let tKeyFacade: TKeyJSFacade?
    let webView = GlobalWebView.requestWebView()
    let viewModel: CreateWalletViewModel

    private var result = PassthroughSubject<Void, Never>() // TODO: - Complete this when next navigation is done

    let socialSignInDelegatedCoordinator: SocialSignInDelegatedCoordinator
    let bindingPhoneNumberDelegatedCoordinator: BindingPhoneNumberDelegatedCoordinator

    init(parent: UIViewController) {
        parentViewController = parent
        tKeyFacade = TKeyJSFacade(wkWebView: webView)
        viewModel = CreateWalletViewModel(tKeyFacade: nil)

        socialSignInDelegatedCoordinator = .init { [weak viewModel] event in
            try await viewModel?.onboardingStateMachine.accept(event: .socialSignInEvent(event))
        }

        bindingPhoneNumberDelegatedCoordinator = .init { [weak viewModel] event in
            try await viewModel?.onboardingStateMachine.accept(event: .bindingPhoneNumberEvent(event))
        }

        super.init()
    }

    deinit {
        webView.removeFromSuperview()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Create root view controller
        guard let viewController = buildViewController(state: viewModel.onboardingStateMachine.currentState) else {
            return Empty().eraseToAnyPublisher()
        }

        navigationController = navigationController ?? UINavigationController(rootViewController: viewController)
        navigationController!.modalPresentationStyle = .fullScreen

        socialSignInDelegatedCoordinator.rootViewController = navigationController
        bindingPhoneNumberDelegatedCoordinator.rootViewController = navigationController

        Task {
            DispatchQueue.main.async { self.navigationController?.showIndetermineHud() }
            try await initializeTkey()
        }

        viewModel.onboardingStateMachine
            .stateStream
            .removeDuplicates()
            .dropFirst()
            .pairwise()
            .receive(on: RunLoop.main)
            .sink { [weak self] pairwise in
                self?.navigate(from: pairwise.previous, to: pairwise.current)
            }
            .store(in: &subscriptions)

        parentViewController.present(navigationController!, animated: true)

        return result.eraseToAnyPublisher()
    }

    func initializeTkey() async throws {
        try await tKeyFacade?.initialize()
        DispatchQueue.main.async { self.navigationController?.hideHud() }
    }

    // MARK: Navigation

    private func navigate(from: CreateWalletFlowState?, to: CreateWalletFlowState) {
        // Handler final states
        // TODO: handle result
        if case let .finish(result) = to {
            switch result {
            default:
                self.result.send()
                return
            }
        }

        guard let navigationController = navigationController else { return }

        // TODO: Add empty screen
        let vc = buildViewController(state: to) ?? UIViewController()

        if to.step > (from?.step ?? -1) {
            navigationController.setViewControllers([vc], animated: true)
        } else {
            navigationController.setViewControllers([vc] + navigationController.viewControllers, animated: false)
            navigationController.popToViewController(vc, animated: true)
        }
    }

    private func buildViewController(state: CreateWalletFlowState) -> UIViewController? {
        switch state {
        case let .socialSignIn(innerState):
            return socialSignInDelegatedCoordinator.buildViewController(for: innerState)
        case let .bindingPhoneNumber(_, _, _, innerState):
            return bindingPhoneNumberDelegatedCoordinator.buildViewController(for: innerState)
        default:
            return nil
        }
    }
}
