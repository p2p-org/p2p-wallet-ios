//
//  RecoveryKitDevicesCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Combine
import Foundation
import Onboarding
import Resolver
import SwiftUI

final class RecoveryKitDevicesCoordinator: Coordinator<Void> {
    let result = PassthroughSubject<Void, Never>()
    let navigationController: UINavigationController

    var prevVC: UIViewController?

    @Injected var notificationService: NotificationService

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let vm = RecoveryKitDevicesViewModel()
        let view = RecoveryKitDevicesView(viewModel: vm)
        let vc = UIHostingController(rootView: view)

        vc.title = L10n.devices

        vm.action.sink { [weak self] action in
            switch action {
            case .setup:
                self?.promptAlertBeforeSetup()
            }
        }.store(in: &subscriptions)

        prevVC = navigationController.topViewController
        navigationController.pushViewController(vc, animated: true)

        return result
            .prefix(1)
            .eraseToAnyPublisher()
    }

    func promptAlertBeforeSetup() {
        let alert = UIAlertController(
            title: L10n.areYouSureYouWantToUpdateYourAuthorizationDevice,
            message: L10n.youWillNotBeAbleToUseTheOldDeviceForRecovery,
            preferredStyle: .alert
        )

        let updateAction = UIAlertAction(title: L10n.update, style: .destructive) { [weak self] _ in
            self?.setup()
        }
        alert.addAction(updateAction)

        let cancelAction = UIAlertAction(title: L10n.cancel, style: .default)
        alert.addAction(cancelAction)
        alert.preferredAction = updateAction

        navigationController.present(alert, animated: true)
    }

    func setup() {
        let userWalletManager: UserWalletManager = Resolver.resolve()
        let facadeManager: TKeyFacadeManager = Resolver.resolve()

        Task {
            if
                let facade = facadeManager.latest,
                let facadeEthAddress = await facade.ethAddress,
                facadeEthAddress == userWalletManager.wallet?.ethAddress
            {
                startMigration(facade: facade)
            } else {
                reAuth()
            }
        }
    }

    func reAuth() {
        let facadeManager: TKeyFacadeManager = Resolver.resolve()
        let walletMetadata: WalletMetadataService = Resolver.resolve()

        guard let metadata = walletMetadata.metadata.value else {
            // Notify
            notificationService.showInAppNotification(.message("Service isn't ready"))

            // Finish
            guard let prevVC = prevVC else { return }
            navigationController.popToViewController(prevVC, animated: true)
            result.send(completion: .finished)

            return
        }

        let facade = facadeManager.create(
            BackgroundWebViewManager.requestWebView(),
            with: TKeyJSFacadeConfiguration(
                torusEndpoint: OnboardingConfig.shared.torusEndpoint,
                torusNetwork: OnboardingConfig.shared.torusNetwork,
                verifierStrategyResolver: { authProvider in
                    switch authProvider {
                    case "google":
                        return .aggregate(
                            verifier: OnboardingConfig.shared.torusGoogleVerifier,
                            subVerifier: OnboardingConfig.shared.torusGoogleSubVerifier
                        )
                    case "apple":
                        return .single(
                            verifier: OnboardingConfig.shared.torusAppleVerifier
                        )
                    default:
                        fatalError("Invalid")
                    }
                },
                isDebug: Environment.current == .debug
            )
        )

        let coordinator = ReauthenticationWithoutDeviceShareCoordinator(
            facade: facade,
            metadata: metadata,
            navigationController: navigationController
        )

        coordinate(to: coordinator)
            .sink { [weak self] result in
                switch result {
                case let .success(facade):
                    self?.startMigration(facade: facade)
                case .failure:
                    self?.notificationService.showToast(title: "❌", text: L10n.SomethingWentWrong.pleaseTryAgain)
                case .cancel:
                    guard let prevVC = self?.prevVC else { return }
                    self?.navigationController.popToViewController(prevVC, animated: true)
                    self?.result.send(completion: .finished)
                }
            }
            .store(in: &subscriptions)
    }

    func startMigration(facade: TKeyFacade) {
        let coordinator = DeviceShareMigrationCoordinator(facade: facade, navigationController: navigationController)

        coordinate(to: coordinator)
            .sink { [weak self] result in
                switch result {
                case .finish:
                    self?.notificationService.showInAppNotification(
                        .custom("✌️", L10n.theDeviceWasSuccessfullyChanged)
                    )
                    guard let prevVC = self?.prevVC else { return }
                    self?.navigationController.popToViewController(prevVC, animated: true)
                    self?.result.send(completion: .finished)

                case .error:
                    self?.notificationService.showToast(title: "❌", text: L10n.SomethingWentWrong.pleaseTryAgain)
                }
            }
            .store(in: &subscriptions)
    }
}
