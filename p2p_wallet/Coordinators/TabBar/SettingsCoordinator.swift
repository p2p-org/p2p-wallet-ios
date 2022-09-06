//
//  SettingsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 30.08.2022.
//

import Combine
import Resolver
import UIKit

final class SettingsCoordinator: Coordinator<Void> {
    @Injected private var pinStorage: PincodeStorageType

    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SettingsViewModel()
        let settingsView = SettingsView(viewModel: viewModel)
        let settingsVC = settingsView.asViewController(withoutUIKitNavBar: false)
        settingsVC.title = L10n.settings
        navigationController.setViewControllers([settingsVC], animated: false)

        viewModel.openAction
            .sink(receiveValue: { [unowned self] action in
                switch action {
                case .username:
                    let vc = Settings.NewUsernameViewController(viewModel: Settings.ViewModel())
                    navigationController.pushViewController(vc, animated: true)
                case let .reserveUsername(userAddress):
                    let vm = ReserveName.ViewModel(
                        kind: .independent,
                        owner: userAddress,
                        reserveNameHandler: Settings.ViewModel(),
                        goBackOnCompletion: true,
                        checkBeforeReserving: true
                    )
                    let vc = ReserveName.ViewController(viewModel: vm)
                    navigationController.pushViewController(vc, animated: true)
                case .recoveryKit:
                    break
                case .yourPin:
                    let createPincodeVC = WLCreatePincodeVC(
                        createPincodeTitle: L10n.setUpANewWalletPIN,
                        confirmPincodeTitle: L10n.confirmPINCode
                    )
                    createPincodeVC.modalPresentationStyle = .fullScreen

                    createPincodeVC.onSuccess = { [weak self, weak createPincodeVC] pincode in
                        self?.pinStorage.save(pincode)
                        createPincodeVC?.dismiss(animated: true) {
                            Resolver.resolve(NotificationService.self)
                                .showInAppNotification(.done(L10n.youHaveSuccessfullySetYourPIN))
                        }
                    }
                    createPincodeVC.onCancel = { [weak createPincodeVC] in
                        createPincodeVC?.dismiss(animated: true)
                    }

                    navigationController.present(createPincodeVC, animated: true)
                case .network:
                    let coordinator = NetworkCoordinator(navigationController: navigationController)
                    coordinate(to: coordinator)
                }
            })
            .store(in: &subscriptions)

        let closeSubject = PassthroughSubject<Void, Never>()
        settingsVC.onClose = {
            closeSubject.send()
        }
        return closeSubject.eraseToAnyPublisher()
    }
}
