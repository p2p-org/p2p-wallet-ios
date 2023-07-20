// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Combine
import Resolver
import SwiftUI
import UIKit

final class RecoveryKitCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var walletSettings: WalletSettings

    private let navigationController: UINavigationController
    private let transition = PanelTransition()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let result = PassthroughSubject<Void, Never>()

        let vm = RecoveryKitViewModel()

        vm.actions
            .sink { [weak self, weak navigationController] action in
                switch action {
                case .seedPhrase:
                    let vm = SeedPhraseDetailViewModel()
                    let vc = KeyAppHostingController(rootView: SeedPhraseDetailView(viewModel: vm))
                    vc.title = L10n.seedPhraseDetails
                    navigationController?.pushViewController(vc, animated: true)
                case .deleteAccount:
                    if self?.walletSettings.deleteWeb3AuthRequest == nil {
                        self?.confirmDeleteAccountDialog()
                    } else {
                        self?.openSuccessfulDeletionRequestView()
                    }
                case .devices:
                    self?.openDevices()
                default:
                    break
                }
            }.store(in: &subscriptions)

        let vc = KeyAppHostingController(rootView: RecoveryKitView(viewModel: vm))
        vc.title = L10n.securityAndPrivacy
        vc.hidesBottomBarWhenPushed = true
        vc.onClose = {
            result.send()
        }

        navigationController.pushViewController(vc, animated: true)

        return result.prefix(1).eraseToAnyPublisher()
    }

    func confirmDeleteAccountDialog() {
        let alert = UIAlertController(
            title: L10n.areYouSureYouWantToDeleteYourAccount,
            message: L10n.theDataWillBeClearedWithoutThePossibilityOfRecovery,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: L10n.yesDeleteMyAccount, style: .destructive) { _ in
            self.analyticsManager.log(event: .confirmDeleteAccount)
            self.authenticationHandler.authenticate(
                presentationStyle: .init(
                    options: [.fullscreen],
                    completion: { [weak self] _ in
                        self?.openDeleteAccountView()
                    }
                )
            )
        })
        alert.addAction(.init(title: L10n.goBack, style: .cancel))

        navigationController.present(alert, animated: true, completion: nil)
    }

    func openDeleteAccountView() {
        var view = DeleteMyAccountView()
        view.didRequestDelete = { [weak self] in
            self?.navigationController.popViewController(animated: true) { [weak self] in
                self?.openSuccessfulDeletionRequestView()
            }
        }

        let vc = UIHostingController(rootView: view)
        navigationController.pushViewController(vc, animated: true)
    }

    func openSuccessfulDeletionRequestView() {
        var view = DeleteRequestSuccessView()
        view.onDone = { [weak self] in
            self?.navigationController.dismiss(animated: true)
        }

        transition.containerHeight = view.viewHeight
        let viewController = view.asViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.view.layer.cornerRadius = 16
        navigationController.transitioningDelegate = transition
        navigationController.modalPresentationStyle = .custom
        self.navigationController.present(navigationController, animated: true)
    }

    func openDevices() {
        let coordinator = RecoveryKitDevicesCoordinator(navigationController: navigationController)
        coordinate(to: coordinator)
            .sink { _ in }
            .store(in: &subscriptions)
    }
}

private final class KeyAppHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}
