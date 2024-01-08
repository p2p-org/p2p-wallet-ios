import Combine
import Resolver
import UIKit

final class SettingsCoordinator: Coordinator<Void> {
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
                    let vc = NewUsernameViewController()
                    navigationController.pushViewController(vc, animated: true)
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
