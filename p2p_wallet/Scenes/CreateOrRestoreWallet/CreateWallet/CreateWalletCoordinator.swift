// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
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

    private var subject = PassthroughSubject<Void, Never>() // TODO: - Complete this when next navigation is done

    init(parent: UIViewController) {
        parentViewController = parent
        tKeyFacade = TKeyJSFacade(wkWebView: webView)
        viewModel = CreateWalletViewModel(tKeyFacade: tKeyFacade)

        super.init()
    }

    deinit {
        webView.removeFromSuperview()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Create root view controller
        let viewController = buildViewController(state: viewModel.onboardingStateMachine.currentState)
        navigationController = navigationController ?? UINavigationController(rootViewController: viewController)
        navigationController!.modalPresentationStyle = .fullScreen

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

        return subject
            .eraseToAnyPublisher()
    }

    func initializeTkey() async throws {
        try await tKeyFacade?.initialize()
        DispatchQueue.main.async { self.navigationController?.hideHud() }
    }

    // MARK: Navigation

    private func navigate(from: CreateWalletState?, to: CreateWalletState) {
        // Handler final states
        // TODO: return result
        switch viewModel.onboardingStateMachine.currentState {
        case .finishWithoutResult:
            navigationController?.dismiss(animated: true)
            return
        case .finishWithRerouteToRestore:
            navigationController?.dismiss(animated: true)
            return
        default:
            break
        }

        guard let navigationController = navigationController else { return }
        let vc = buildViewController(state: to)

        switch viewModel.onboardingStateMachine.currentState {
        case .socialSignInAccountWasUsed:
            navigationController.pushViewController(vc, animated: true)
        default:
            if to.step > (from?.step ?? 0) {
                navigationController.setViewControllers([vc], animated: true)
            } else {
                navigationController.setViewControllers([vc] + navigationController.viewControllers, animated: false)
                navigationController.popToViewController(vc, animated: true)
            }
        }
    }

    private func buildViewController(state: CreateWalletState) -> UIViewController {
        switch state {
        case .socialSignIn:
            let vc = SocialSignInViewController(viewModel: .init(createWalletViewModel: viewModel))
            vc.viewModel.output.onInfo.sink { [weak self] in self?.showInfo() }.store(in: &subscriptions)
            return vc
        case let .socialSignInAccountWasUsed(provider, usedEmail):
            let vm = SocialSignInAccountHasBeenUsedViewModel(
                createWalletViewModel: viewModel,
                email: usedEmail,
                signInProvider: provider
            )
            let vc = SocialSignInAccountHasBeenUsedViewController(viewModel: vm)
            return vc
        case let .enterPhoneNumber(solPrivateKey, ethPublicKey, deviceShare):
            UserDefaults.standard.set(deviceShare, forKey: "deviceShare")

            let vc = EnterPhoneNumberViewController(sol: solPrivateKey, eth: ethPublicKey, deviceShare: deviceShare)
            vc.onFlagSelection.sinkAsync { [weak self, weak vc] in
                guard let result = try await self?.selectCountry() else { return }
                vc?.currentFlag.send(result)
            }.store(in: &subscriptions)
            return vc
        default:
            return UIViewController()
        }
    }

    public func showInfo() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        navigationController?.present(vc, animated: true)
    }

    public func selectCountry() async throws -> Country? {
        let coordinator = ChoosePhoneCodeCoordinator(
            selectedCountry: nil,
            presentingViewController: navigationController!
        )
        return try await coordinator.start().async()
    }
}
