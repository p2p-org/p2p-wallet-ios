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
    @Injected private var helpLauncher: HelpCenterLauncher

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
            .sink(receiveValue: { [unowned self, weak viewModel] action in
                guard let viewModel = viewModel else { return }
                switch action {
                case .username:
                    let vc = NewUsernameViewController(viewModel: viewModel)
                    navigationController.pushViewController(vc, animated: true)
                case .support:
                    helpLauncher.launch()
                case .reserveUsername:
                    coordinate(to: CreateUsernameCoordinator(navigationOption: .settings(parent: navigationController)))
                        .sink { [unowned self] in
                            self.navigationController.popToViewController(settingsVC, animated: true)
                        }
                        .store(in: &subscriptions)
                case .recoveryKit:
                    let coordinator = RecoveryKitCoordinator(navigationController: navigationController)
                    coordinate(to: coordinator)
                        .sink(receiveValue: {})
                        .store(in: &subscriptions)
                case .yourPin:
                    let coordinator = PincodeChangeCoordinator(navVC: navigationController)
                    coordinate(to: coordinator)
                        .sink(receiveValue: { [unowned self] _ in
                            navigationController.popToRootViewController(animated: true)
                        })
                        .store(in: &subscriptions)
                case .network:
                    let coordinator = NetworkCoordinator(navigationController: navigationController)
                    coordinate(to: coordinator)
                        .sink(receiveValue: {})
                        .store(in: &subscriptions)
                case let .share(item):
                    let vc = UIActivityViewController(activityItems: [item], applicationActivities: nil)
                    navigationController.present(vc, animated: true, completion: nil)
                case .accessToPhoto:
                    PhotoLibraryAlertPresenter().present(on: navigationController)
                }
            })
            .store(in: &subscriptions)

        let closeSubject = PassthroughSubject<Void, Never>()
        settingsVC.onClose = {
            closeSubject.send()
        }
        return closeSubject.prefix(1).eraseToAnyPublisher()
    }
}
