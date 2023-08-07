import Combine
import CountriesAPI
import Resolver
import UIKit

final class SettingsCoordinator: Coordinator<Void> {
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
            .sink(receiveValue: { [unowned self] action in
                switch action {
                case .username:
                    let vc = NewUsernameViewController()
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
                case .country:
                    coordinate(to: ChooseItemCoordinator<Region>(
                        title: L10n.selectYourCountry,
                        controller: settingsVC,
                        service: ChooseCountryService(),
                        chosen: Defaults.region,
                        showDoneButton: true
                    ))
                    .sink { result in
                        switch result {
                            case .item(let item):
                            if let region = item as? Region {
                                viewModel.region = region
                            } else {
                                assert(true)
                            }
                            case .cancel: break
                        }
                    }.store(in: &subscriptions)
                }
            })
            .store(in: &subscriptions)

        return settingsVC.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
